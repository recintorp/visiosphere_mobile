import 'package:flutter_test/flutter_test.dart';
import 'package:visiosphere_mobile/core/network/dio_client.dart';

void main() {
  test('unauthorized callback can be cleared without leaving a throw stub', () {
    DioClient.setUnauthorizedCallback(() {});
    expect(DioClient.hasUnauthorizedCallback, isTrue);

    DioClient.clearUnauthorizedCallback();
    expect(DioClient.hasUnauthorizedCallback, isFalse);
  });
}
