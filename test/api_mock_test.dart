import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';

// Mock class menggunakan mocktail
class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
  });

  group('API Integration Test dengan Mocktail', () {
    test('Mengembalikan data sukses (200) dari endpoint mock', () async {
      // Arrange
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/health'),
          statusCode: 200,
          data: {'status': 'ok'},
        ),
      );

      // Act
      final response = await mockDio.get('/api/v1/health');

      // Assert
      expect(response.statusCode, 200);
      expect(response.data['status'], 'ok');
      verify(() => mockDio.get('/api/v1/health')).called(1);
    });

    test('Menangani error (404) dari endpoint mock', () async {
      // Arrange
      when(() => mockDio.get(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/not-found'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/not-found'),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act & Assert
      expect(
        () => mockDio.get('/api/v1/not-found'),
        throwsA(isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          404,
        )),
      );
      verify(() => mockDio.get('/api/v1/not-found')).called(1);
    });
  });
}
