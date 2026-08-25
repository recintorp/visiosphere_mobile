import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Minimal MJPEG (motion-JPEG) player built on Dio's streaming response.
///
/// Why custom: flutter_mjpeg failed to render this stream over the Cloudflare
/// tunnel on Android, and webview_flutter 4.x conflicts with quill_html_editor.
/// Dio is already a dependency, so this adds no new packages. We read the
/// `multipart/x-mixed-replace` byte stream and extract each JPEG frame by its
/// SOI (0xFFD8) / EOI (0xFFD9) markers — format-agnostic and robust.
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

  final Dio _dio = Dio(BaseOptions(
    // Long-lived stream: no receive timeout, generous connect timeout.
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: null,
  ));

  CancelToken? _cancel;
  StreamSubscription<Uint8List>? _sub;
  Uint8List? _frame;
  Object? _error;
  bool _disposed = false;
  Timer? _retryTimer;

  final List<int> _buffer = [];

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

  void _onChunk(Uint8List chunk) {
    _buffer.addAll(chunk);
    // Extract every complete JPEG currently in the buffer.
    while (true) {
      final start = _indexOf(_buffer, _soi0, _soi1, 0);
      if (start < 0) {
        // No frame start yet; cap buffer growth to avoid unbounded memory.
        if (_buffer.length > 1 << 20) _buffer.clear();
        return;
      }
      final end = _indexOf(_buffer, _eoi0, _eoi1, start + 2);
      if (end < 0) return; // wait for more bytes
      final frame = Uint8List.fromList(_buffer.sublist(start, end + 2));
      _buffer.removeRange(0, end + 2);
      if (!_disposed) {
        setState(() {
          _frame = frame;
          _error = null;
        });
      }
    }
  }

  int _indexOf(List<int> data, int b0, int b1, int from) {
    for (int i = from; i < data.length - 1; i++) {
      if (data[i] == b0 && data[i + 1] == b1) return i;
    }
    return -1;
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
      _buffer.clear();
      _connect();
    });
  }

  void _restart() {
    _retryTimer?.cancel();
    _cancel?.cancel('url changed');
    _sub?.cancel();
    _buffer.clear();
    _frame = null;
    _connect();
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _cancel?.cancel('disposed');
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_frame != null) {
      return Image.memory(
        _frame!,
        fit: widget.fit,
        gaplessPlayback: true,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (_error != null) return widget.error(context, _error!);
    return widget.loading(context);
  }
}
