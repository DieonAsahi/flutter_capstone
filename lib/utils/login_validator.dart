class LoginValidationResult {
  final bool isValid;
  final String? message;

  LoginValidationResult(this.isValid, {this.message});
}

LoginValidationResult validateLoginInput({
  required String username,
  required String password,
}) {
  if (username.isEmpty) {
    return LoginValidationResult(
      false,
      message: 'Isi username anda',
    );
  }

  if (password.isEmpty) {
    return LoginValidationResult(
      false,
      message: 'Isi password anda',
    );
  }

  if (password.length < 6) {
    return LoginValidationResult(
      false,
      message: 'Password minimal 6 karakter',
    );
  }

  return LoginValidationResult(true);
}

Map<String, dynamic> buildLoginPayload({
  required String username,
  required String password,
}) {
  return {
    'username': username,
    'password': password,
  };
}
