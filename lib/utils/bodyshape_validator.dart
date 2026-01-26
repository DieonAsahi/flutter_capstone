class BodyShapeValidationResult {
  final bool isValid;
  final String? message;

  BodyShapeValidationResult(this.isValid, {this.message});
}

BodyShapeValidationResult validateBodyMeasurements({
  required String bust,
  required String waist,
  required String hips,
}) {
  if (bust.isEmpty || waist.isEmpty || hips.isEmpty) {
    return BodyShapeValidationResult(
      false,
      message: "Mohon isi semua data",
    );
  }

  final bustVal = double.tryParse(bust.replaceAll(',', '.'));
  final waistVal = double.tryParse(waist.replaceAll(',', '.'));
  final hipsVal = double.tryParse(hips.replaceAll(',', '.'));

  if (bustVal == null || waistVal == null || hipsVal == null) {
    return BodyShapeValidationResult(
      false,
      message: "Harap masukan data yang benar (hanya angka)",
    );
  }

  if (bustVal <= 0 || waistVal <= 0 || hipsVal <= 0) {
    return BodyShapeValidationResult(
      false,
      message: "Ukuran tidak boleh 0 atau negatif",
    );
  }

  if (bustVal > 300 || waistVal > 300 || hipsVal > 300) {
    return BodyShapeValidationResult(
      false,
      message: "Ukuran tidak logis (Maksimal 300 cm)",
    );
  }

  return BodyShapeValidationResult(true);
}
