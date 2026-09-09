import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Minimal MJPEG (motion-JPEG) player built on Dio's streaming response.
///
/// Why custom: flutter_mjpeg failed to render this stream over the Cloudflare
/// tunnel on Android, and webview_flutter 4.x conflicts with quill_html_editor.
/// Dio is already a dependency, so this adds no new packages. We read the
/// `multipart/x-mixed-replace` byte stream and extract each JPEG frame by its
/// SOI (0xFFD8) / EOI (0xFFD9) markers — format-agnostic and robust.
///
/// ── WHY THIS WAS REWRITTEN (Apptim: 55.5% avg CPU, 231.3 MB) ───────────────
///
/// The parsing was correct but did four expensive things per frame, and the
/// CCTV grid mounts one of these PER CAMERA, so every cost multiplied:
///
///  1. The accumulation buffer was a growable `List<int>`, not a `Uint8List`.
///     Dart stores that as tagged words — roughly 8 bytes of heap per byte of
///     JPEG — and `addAll` copied every incoming byte into it one element at a
///     time. At ~30 fps that is megabytes per second of pure allocation churn,
///     which is GC time, which is CPU.
///
///  2. `_indexOf` restarted its scan at index 0 on EVERY chunk, and chunks
///     arrive several times per frame. Re-reading the same bytes over and over
///     made parsing O(n²) in the buffer length.
///
///  3. Every completed frame called `setState` immediately, so the widget
///     rebuilt and decoded at whatever rate the server pushed — even when the
///     device could not keep up. Frames were never dropped, so the app fell
///     further behind the harder it worked.
///
///  4. `Image.memory` decoded each frame at full source resolution and handed
///     it to Flutter's global ImageCache. Every frame is a distinct cache key,
///     so nothing was ever a cache HIT — the cache simply filled with dead
///     frames up to its default 100 MB ceiling. At 640x360 a decoded frame is
///     640*360*4 = 0.92 MB, so roughly 108 frames — about 3.6 seconds of
///     video — is enough to pin 100 MB of otherwise idle memory.
///
/// This version keeps the same public API and the same marker-scanning idea,
/// and changes only how the bytes are held, scanned, paced and decoded:
///
///  * a typed `Uint8List` buffer that grows geometrically and is scanned
///    incrementally — each byte is examined at most once;
///  * only the NEWEST complete frame survives a chunk; older ones are dropped
///    rather than queued, so the display degrades in frame rate instead of in
///    latency;
///  * at most ONE decode in flight at a time;
///  * `ui.instantiateImageCodec` with a `targetWidth` matching the widget's
///    real on-screen size, painted through `RawImage`. That decodes smaller
///    AND bypasses ImageCache entirely, so a frame's memory is released the
///    moment the next one replaces it.
class MjpegView extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final WidgetBuilder loading;
  final Widget Function(BuildContext context, Object error) error;

  const MjpegView({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    required this.loading,
    required this.error,
  });

  @override
  State<MjpegView> createState() => _MjpegViewState();
}

class _MjpegViewState extends State<MjpegView> {
  static const int _soi0 = 0xFF, _soi1 = 0xD8; // JPEG start
  static const int _eoi0 = 0xFF, _eoi1 = 0xD9; // JPEG end

  /// A frameless stream should not grow without bound. Generous enough for a
  /// large keyframe, small enough that a wedged stream cannot eat the heap.
  static const int _maxBuffer = 4 << 20; // 4 MB

  final Dio _dio = Dio(BaseOptions(
    // Long-lived stream: no receive timeout, generous connect timeout.
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: null,
  ));

  CancelToken? _cancel;
  StreamSubscription<Uint8List>? _sub;
  Object? _error;
  bool _disposed = false;
  Timer? _retryTimer;

  // ── Byte buffer ───────────────────────────────────────────────────────────
  // Typed, with an explicit valid length so it can be reused between chunks
  // instead of reallocated.
  Uint8List _buf = Uint8List(0);
  int _len = 0;

  /// Index of the SOI marker of the frame being assembled, or -1 while looking.
  int _frameStart = -1;

  /// Next index to examine. Bytes before this have already been scanned.
  int _searchFrom = 0;

  // ── Decode pipeline ───────────────────────────────────────────────────────
  /// Newest complete frame not yet decoded. Overwritten, never queued.
  Uint8List? _pending;
  bool _decoding = false;
  ui.Image? _image;

  /// Physical-pixel width to decode to; set from the widget's real layout.
  int? _targetWidth;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void didUpdateWidget(covariant MjpegView old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _restart();
    }
  }

  Future<void> _connect() async {
    _cancel = CancelToken();
    _error = null;
    try {
      final resp = await _dio.get<ResponseBody>(
        widget.url,
        options: Options(
          responseType: ResponseType.stream,
          // Avoid any gzip on the stream so JPEG markers stay intact.
          headers: const {'Accept-Encoding': 'identity'},
        ),
        cancelToken: _cancel,
      );
      _sub = resp.data!.stream.listen(
        _onChunk,
        onError: _fail,
        onDone: () {
          // Stream closed by server/proxy — reconnect unless disposed.
          if (!_disposed) _scheduleRetry();
        },
        cancelOnError: true,
      );
    } catch (e) {
      _fail(e);
    }
  }

  // ── Buffer management ─────────────────────────────────────────────────────

  void _append(Uint8List chunk) {
    final needed = _len + chunk.length;
    if (needed > _buf.length) {
      var cap = _buf.isEmpty ? 64 << 10 : _buf.length;
      while (cap < needed) {
        cap <<= 1;
      }
      final grown = Uint8List(cap);
      grown.setRange(0, _len, _buf);
      _buf = grown;
    }
    _buf.setRange(_len, needed, chunk);
    _len = needed;
  }

  /// Drop everything before [upTo], keeping the tail. Indices move with it.
  void _discard(int upTo) {
    if (upTo <= 0) return;
    final remaining = _len - upTo;
    // Copied forward, by hand, rather than with setRange: source and
    // destination are the SAME buffer and they overlap. A forward loop is
    // always correct here because the destination index is strictly lower than
    // the source index. `remaining` is normally just the few bytes of the
    // multipart boundary that follow a frame, so this is cheap.
    for (int i = 0; i < remaining; i++) {
      _buf[i] = _buf[upTo + i];
    }
    _len = remaining < 0 ? 0 : remaining;
    _frameStart = _frameStart < 0 ? -1 : _frameStart - upTo;
    _searchFrom = _searchFrom - upTo;
    if (_searchFrom < 0) _searchFrom = 0;
  }

  int _indexOfMarker(int b0, int b1, int from) {
    final end = _len - 1;
    for (int i = from < 0 ? 0 : from; i < end; i++) {
      if (_buf[i] == b0 && _buf[i + 1] == b1) return i;
    }
    return -1;
  }

  void _onChunk(Uint8List chunk) {
    _append(chunk);

    // Pull out every complete JPEG the buffer now holds, keeping only the last
    // one. Decoding the intermediate frames would be work whose result is
    // overwritten before it is ever painted.
    Uint8List? newest;
    while (true) {
      if (_frameStart < 0) {
        final start = _indexOfMarker(_soi0, _soi1, _searchFrom);
        if (start < 0) {
          // Nothing but junk so far. Keep the final byte: a marker can be
          // split across two chunks.
          _searchFrom = _len > 0 ? _len - 1 : 0;
          _discard(_searchFrom);
          break;
        }
        _frameStart = start;
        _searchFrom = start + 2;
      }

      final end = _indexOfMarker(_eoi0, _eoi1, _searchFrom);
      if (end < 0) {
        // Frame still arriving. Resume the EOI search where we stopped.
        _searchFrom = _len > _frameStart + 2 ? _len - 1 : _frameStart + 2;
        // Drop the bytes before the frame we are assembling.
        _discard(_frameStart);
        break;
      }

      newest = _buf.sublist(_frameStart, end + 2);
      _discard(end + 2);
      _frameStart = -1;
      _searchFrom = 0;
    }

    if (_len > _maxBuffer) {
      // Wedged: no frame boundary in 4 MB. Start clean rather than grow.
      _len = 0;
      _frameStart = -1;
      _searchFrom = 0;
    }

    if (newest != null) {
      _pending = newest;
      unawaited(_pump());
    }
  }

  // ── Decode ────────────────────────────────────────────────────────────────

  /// Decode the newest pending frame, one at a time.
  ///
  /// Serialising this is the point: while a decode is running, incoming frames
  /// replace `_pending` instead of stacking up, so a device that cannot manage
  /// the full frame rate simply shows fewer frames rather than falling behind.
  Future<void> _pump() async {
    if (_decoding || _disposed) return;
    final bytes = _pending;
    if (bytes == null) return;
    _pending = null;
    _decoding = true;
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: _targetWidth,
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (_disposed) {
        frame.image.dispose();
        return;
      }
      final previous = _image;
      setState(() {
        _image = frame.image;
        _error = null;
      });
      // Released only after this frame has actually been painted — disposing
      // it inline can pull the texture out from under the current frame.
      if (previous != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
      }
    } catch (_) {
      // A single corrupt frame is not a stream failure. Skip it; the next
      // frame is 33 ms away.
    } finally {
      _decoding = false;
      if (!_disposed && _pending != null) unawaited(_pump());
    }
  }

  void _fail(Object e) {
    if (_disposed) return;
    setState(() => _error = e);
    _scheduleRetry();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 2), () {
      if (_disposed) return;
      _sub?.cancel();
      _resetBuffer();
      _connect();
    });
  }

  void _restart() {
    _retryTimer?.cancel();
    _cancel?.cancel('url changed');
    _sub?.cancel();
    _resetBuffer();
    final previous = _image;
    _image = null;
    previous?.dispose();
    _connect();
  }

  void _resetBuffer() {
    _len = 0;
    _frameStart = -1;
    _searchFrom = 0;
    _pending = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _cancel?.cancel('disposed');
    _sub?.cancel();
    _image?.dispose();
    _image = null;
    _dio.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_image != null) {
      // LayoutBuilder gives the tile's real size, so frames are decoded at the
      // size they are drawn instead of at full sensor resolution. On the 2-up
      // camera grid that is a little over a quarter of the pixels.
      //
      // The very first frame decodes at full size because nothing has been laid
      // out yet; every frame after it uses the measured width. Assigning here
      // does not call setState, so it cannot cause a rebuild loop.
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.hasBoundedWidth && constraints.maxWidth > 0) {
            final dpr = MediaQuery.devicePixelRatioOf(context);
            _targetWidth = (constraints.maxWidth * dpr).round();
          }
          return SizedBox.expand(
            child: RawImage(
              image: _image,
              fit: widget.fit,
              filterQuality: FilterQuality.low,
            ),
          );
        },
      );
    }
    if (_error != null) return widget.error(context, _error!);
    return widget.loading(context);
  }
}
