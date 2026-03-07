class Pastor {
  final String id;
  final String name;
  final String title;
  final String photoUrl;
  final bool isSeniorPastor;

  Pastor({
    required this.id,
    required this.name,
    required this.title,
    required this.photoUrl,
    this.isSeniorPastor = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'title': title,
        'photoUrl': photoUrl,
        'isSeniorPastor': isSeniorPastor,
      };

  factory Pastor.fromJson(Map<String, dynamic> json) => Pastor(
        id: json['id'],
        name: json['name'],
        title: json['title'],
        photoUrl: json['photoUrl'],
        isSeniorPastor: json['isSeniorPastor'] ?? false,
      );
}
