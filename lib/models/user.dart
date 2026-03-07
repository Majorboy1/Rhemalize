class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final bool isAdmin;
  final int currentStreak;
  final DateTime? lastListenDate;
  final List<String> favoriteSermonIds;
  final Map<String, int> listenCounts;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.isAdmin = false,
    this.currentStreak = 0,
    this.lastListenDate,
    this.favoriteSermonIds = const [],
    this.listenCounts = const {},
  });

  bool isFavorite(String sermonId) =>
      favoriteSermonIds.contains(sermonId);

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    bool? isAdmin,
    int? currentStreak,
    DateTime? lastListenDate,
    List<String>? favoriteSermonIds,
    Map<String, int>? listenCounts,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      currentStreak: currentStreak ?? this.currentStreak,
      lastListenDate: lastListenDate ?? this.lastListenDate,
      favoriteSermonIds: favoriteSermonIds ?? this.favoriteSermonIds,
      listenCounts: listenCounts ?? this.listenCounts,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'isAdmin': isAdmin,
        'currentStreak': currentStreak,
        'lastListenDate': lastListenDate?.toIso8601String(),
        'favoriteSermonIds': favoriteSermonIds,
        'listenCounts': listenCounts,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        photoUrl: json['photoUrl'],
        isAdmin: json['isAdmin'] ?? false,
        currentStreak: json['currentStreak'] ?? 0,
        lastListenDate: json['lastListenDate'] != null
            ? DateTime.parse(json['lastListenDate'])
            : null,
        favoriteSermonIds:
            List<String>.from(json['favoriteSermonIds'] ?? []),
        listenCounts:
            Map<String, int>.from(json['listenCounts'] ?? {}),
      );
}
