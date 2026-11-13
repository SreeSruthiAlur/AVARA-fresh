import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AvaraApiClient Network Error & Timeout Tests', () {
    test('Request timeout is configured to 10 seconds', () {
      expect(AvaraApiClient.requestTimeout, equals(const Duration(seconds: 10)));
    });

    test('Network error message matches required user-friendly text', () {
      expect(
        AvaraApiClient.kNetworkErrorMessage,
        equals('Unable to connect to AVARA servers. Please check your internet connection and try again.'),
      );
    });

    test('notifyNetworkError fires onNetworkError listener', () {
      String? reportedError;
      AvaraApiClient.onNetworkError = (msg) {
        reportedError = msg;
      };

      AvaraApiClient.notifyNetworkError();

      expect(reportedError, equals(AvaraApiClient.kNetworkErrorMessage));
      AvaraApiClient.onNetworkError = null;
    });

    test('Unreachable server throws friendly AvaraApiException instead of crashing with SocketException', () async {
      await HttpOverrides.runZoned(() async {
        String? notifiedMessage;
        AvaraApiClient.onNetworkError = (msg) {
          notifiedMessage = msg;
        };

        try {
          await AvaraApiClient.instance.get('/test_unreachable');
          fail('Should have thrown AvaraApiException');
        } on AvaraApiException catch (e) {
          expect(e.message, equals(AvaraApiClient.kNetworkErrorMessage));
          expect(notifiedMessage, equals(AvaraApiClient.kNetworkErrorMessage));
        } catch (e) {
          fail('Should not throw raw exception: $e');
        } finally {
          AvaraApiClient.onNetworkError = null;
        }
      }, createHttpClient: (context) {
        throw const SocketException('Connection refused');
      });
    });

    test('Server timeout throws friendly AvaraApiException and notifies UI', () async {
      await HttpOverrides.runZoned(() async {
        String? notifiedMessage;
        AvaraApiClient.onNetworkError = (msg) {
          notifiedMessage = msg;
        };

        try {
          await AvaraApiClient.instance.get('/test_timeout');
          fail('Should have thrown AvaraApiException');
        } on AvaraApiException catch (e) {
          expect(e.statusCode, equals(408));
          expect(e.message, equals(AvaraApiClient.kNetworkErrorMessage));
          expect(notifiedMessage, equals(AvaraApiClient.kNetworkErrorMessage));
        } catch (e) {
          fail('Should not throw raw exception: $e');
        } finally {
          AvaraApiClient.onNetworkError = null;
        }
      }, createHttpClient: (context) {
        throw TimeoutException('Connection timed out');
      });
    });
  });
}
