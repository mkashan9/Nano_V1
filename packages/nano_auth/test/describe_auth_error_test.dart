import 'package:nano_auth/nano_auth.dart';
import 'package:test/test.dart';

void main() {
  test('maps fetch failures to a connection message', () {
    expect(
      describeAuthError(
        Exception(
          'AuthRetryableFetchException(message: ClientException: Failed to fetch)',
        ),
      ),
      'Could not reach Nano servers. Check your connection and try again.',
    );
  });

  test('passes AuthFailure through unchanged', () {
    expect(describeAuthError(AuthFailure('Profile not found')), 'Profile not found');
  });

  test('maps invalid credentials', () {
    expect(
      describeAuthError(Exception('AuthApiException: Invalid login credentials')),
      'Email or password is incorrect.',
    );
  });
}
