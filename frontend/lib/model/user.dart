class User {

  final int id;
  final String email;
  final String fullName;
  final String role;

  User({required this.id, required this.email, required this.fullName, required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User (
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'client',
    );
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'L\'email est requis';
    if (!value.contains("@")) return 'Format d\'email invalide';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty)  return 'Le mot de passe est requis';
    if (value.length < 6) return 'Doit contenir au moins 6 caracteres';
    return null;
  }
}