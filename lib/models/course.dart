class Course {
  final String? id; // Firestore document ID
  final String name;
  final String code;
  final String colorHex;

  const Course({
    this.id,
    required this.name,
    required this.code,
    required this.colorHex,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'code': code,
    'colorHex': colorHex,
  };

  factory Course.fromMap(String id, Map<String, dynamic> m) => Course(
    id: id,
    name: m['name'] as String,
    code: m['code'] as String,
    colorHex: m['colorHex'] as String,
  );
}