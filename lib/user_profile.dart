import 'date_utils.dart';

class UserProfile {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final String dni;

  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.dni,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as int,
    email: json['email'] as String? ?? '',
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    birthDate: json['birth_date'] == null
        ? null
        : DateTime.parse(json['birth_date'] as String),
    dni: json['dni'] as String? ?? '',
  );

  String get fullName => '$firstName $lastName'.trim();
  String get initials => initialsFor(fullName);
  String get birthDateLabel => birthDate == null ? '-' : formatDate(birthDate!);
}
