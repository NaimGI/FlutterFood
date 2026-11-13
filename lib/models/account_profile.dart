class AccountProfile {
  const AccountProfile({
    required this.id,
    required this.login,
    required this.totalSpent,
  });

  final int id;
  final String login;
  final double totalSpent;

  factory AccountProfile.fromJson(Map<String, dynamic> json) => AccountProfile(
    id: (json['id'] as num).toInt(),
    login: json['login'] as String,
    totalSpent: (json['totalSpent'] as num).toDouble(),
  );
}
