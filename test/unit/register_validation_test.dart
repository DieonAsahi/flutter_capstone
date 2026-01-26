import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi/utils/register_validator.dart';

void main() {
  group('Register Validator Unit Test', () {
    test('Nama kosong mengembalikan error', () {
      final result = RegisterValidator.validate(
        name: '',
        username: 'user123',
        password: 'password123',
        confirmPassword: 'password123',
      );

      expect(result, 'Isi nama anda');
    });

    test('Username kosong mengembalikan error', () {
      final result = RegisterValidator.validate(
        name: 'Araa',
        username: '',
        password: 'password123',
        confirmPassword: 'password123',
      );

      expect(result, 'Isi username anda');
    });

    test('Password kosong mengembalikan error', () {
      final result = RegisterValidator.validate(
        name: 'Araa',
        username: 'user123',
        password: '',
        confirmPassword: '',
      );

      expect(result, 'Isi password anda');
    });

    test('Password kurang dari 8 karakter', () {
      final result = RegisterValidator.validate(
        name: 'Araa',
        username: 'user123',
        password: '12345',
        confirmPassword: '12345',
      );

      expect(result, 'Password minimal 8 karakter');
    });

    test('Konfirmasi password tidak sama', () {
      final result = RegisterValidator.validate(
        name: 'Araa',
        username: 'user123',
        password: 'password123',
        confirmPassword: 'password321',
      );

      expect(result, 'Konfirmasi password tidak sama');
    });

    test('Semua input valid', () {
      final result = RegisterValidator.validate(
        name: 'Araa',
        username: 'user123',
        password: 'password123',
        confirmPassword: 'password123',
      );

      expect(result, null);
    });
  });
}
