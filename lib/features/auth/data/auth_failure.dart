class AuthFailure implements Exception {
  const AuthFailure(this.code, {this.message});

  final String code;
  final String? message;
}
