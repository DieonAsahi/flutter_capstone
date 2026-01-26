import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi/utils/bodyshape_validator.dart';

void main() {
  group('Unit Test - Validasi Body Shape', () {
    test('Input kosong → tidak valid', () {
      final result = validateBodyMeasurements(
        bust: '',
        waist: '70',
        hips: '90',
      );

      expect(result.isValid, false);
      expect(result.message, 'Mohon isi semua data');
    });

    test('Input non-angka → tidak valid', () {
      final result = validateBodyMeasurements(
        bust: 'abc',
        waist: '70',
        hips: '90',
      );

      expect(result.isValid, false);
      expect(result.message, 'Harap masukan data yang benar (hanya angka)');
    });

    test('Nilai 0 atau negatif → tidak valid', () {
      final result = validateBodyMeasurements(
        bust: '-80',
        waist: '0',
        hips: '90',
      );

      expect(result.isValid, false);
      expect(result.message, 'Ukuran tidak boleh 0 atau negatif');
    });

    test('Nilai terlalu besar (>300) → tidak valid', () {
      final result = validateBodyMeasurements(
        bust: '350',
        waist: '70',
        hips: '90',
      );

      expect(result.isValid, false);
      expect(result.message, 'Ukuran tidak logis (Maksimal 300 cm)');
    });

    test('Input valid → lolos validasi', () {
      final result = validateBodyMeasurements(
        bust: '90',
        waist: '70',
        hips: '100',
      );

      expect(result.isValid, true);
      expect(result.message, null);
    });
  });
}
