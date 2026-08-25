import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

/// Result of minting a short-lived MJPEG stream token from the backend.
class StreamToken {
  final String token;
  final int expiresIn; // seconds
  final String? streamBase; // backend-advertised base, may be null
  final DateTime fetchedAt;

  StreamToken({
    required this.token,
    required this.expiresIn,
    this.streamBase,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  /// True a little before real expiry so we refresh proactively.
  bool get isExpiring {
    final age = DateTime.now().difference(fetchedAt).inSeconds;
    return age >= (expiresIn - 30);
  }
}

/// Fetches signed stream tokens. The JWT is attached by DioClient's auth
/// interceptor, so only authenticated users can obtain a token.
class StreamApiService {
  final Dio _dio = DioClient.instance;

  Future<StreamToken> fetchStreamToken() async {
    final response = await _dio.get(ApiConstants.streamTokenEndpoint);
    final data = response.data as Map<String, dynamic>;
    return StreamToken(
      token: data['token'] as String,
      expiresIn: (data['expiresIn'] as num?)?.toInt() ?? 600,
      streamBase: data['streamBase'] as String?,
    );
  }
}
