class RegisterValidator {
  static String? validate({
    required String name,
    required String username,
    required String password,
    required String confirmPassword,
  }) {
    if (name.isEmpty) {
      return 'Isi nama anda';
    }
    if (username.isEmpty) {
      return 'Isi username anda';
    }
    if (password.isEmpty) {
      return 'Isi password anda';
    }
    if (password.length < 8) {
      return 'Password minimal 8 karakter';
    }
    if (password != confirmPassword) {
      return 'Konfirmasi password tidak sama';
    }
    return null;
  }
}
