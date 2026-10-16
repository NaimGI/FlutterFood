class AuthResponse {
  final String? token;
  final String? message;
  final Map<String, dynamic> raw;

  const AuthResponse({this.token, this.message, this.raw = const {}});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: (json['token'] ??
                json['accessToken'] ??
                json['access_token'] ??
                json['jwt'])
            ?.toString(),
        message: json['message']?.toString(),
        raw: json,
      );
}