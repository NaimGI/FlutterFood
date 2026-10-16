class AuthRequest {
  final String login;
  final String password;

  const AuthRequest({required this.login, required this.password});

  Map<String, dynamic> toJson() => {
        'login': login,
        'password': password,
      };
}