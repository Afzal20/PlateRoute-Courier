/// Authenticated user from `POST /auth/login/` -> `user`.
class AppUser {
  const AppUser({required this.id, required this.email, required this.role});

  final int id;
  final String email;
  final String role;

  factory AppUser.fromJson(Map<String, Object?> json) => AppUser(
        id: (json['id'] as num).toInt(),
        email: json['email'] as String,
        role: (json['role'] as String?) ?? 'courier',
      );
}
