import 'dart:convert';

class ChildProfile {
  String name;
  int age;
  String grade;
  String language;
  String? bookImageBase64;

  ChildProfile({
    this.name = '',
    this.age = 8,
    this.grade = 'Class 1',
    this.language = 'English',
    this.bookImageBase64,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'grade': grade,
        'language': language,
      };

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
        name: json['name'] ?? '',
        age: json['age'] ?? 8,
        grade: json['grade'] ?? 'Class 1',
        language: json['language'] ?? 'English',
      );

  String encode() => jsonEncode(toJson());

  factory ChildProfile.decode(String source) =>
      ChildProfile.fromJson(jsonDecode(source));

  bool get isComplete => name.trim().isNotEmpty;
}
