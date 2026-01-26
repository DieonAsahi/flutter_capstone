import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi/utils/login_validator.dart';

void main() {
  group('Unit Test - Login Validation', () {
    test('Username kosong → login gagal', () {
      final result = validateLoginInput(
        username: '',
        password: 'password123',
      );

      expect(result.isValid, false);
      expect(result.message, 'Isi username anda');
    });

    test('Password kosong → login gagal', () {
      final result = validateLoginInput(
        username: 'user123',
        password: '',
      );

      expect(result.isValid, false);
      expect(result.message, 'Isi password anda');
    });

    test('Password < 6 karakter → login gagal', () {
      final result = validateLoginInput(
        username: 'user123',
        password: '123',
      );

      expect(result.isValid, false);
      expect(result.message, 'Password minimal 6 karakter');
    });

    test('Username & password valid → login sukses', () {
      final result = validateLoginInput(
        username: 'user123',
        password: 'password123',
      );

      expect(result.isValid, true);
      expect(result.message, null);
    });

    test('Payload login terbentuk dengan benar', () {
      final payload = buildLoginPayload(
        username: 'user123',
        password: 'password123',
      );

      expect(payload['username'], 'user123');
      expect(payload['password'], 'password123');
    });
  });
}
