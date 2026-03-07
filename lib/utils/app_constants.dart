class AppConstants {
  // App Info
  static const String appName = 'Rhemalize';
  static const String appTagline = 'Hear God\'s Word Today';

  // Bible Verse
  static const String bibleVerse =
      '"So then faith comes by hearing, and hearing by the word of God."';
  static const String bibleReference = 'Romans 10:17';

  // Pastors
  static const String seniorPastorName = 'Pastor Bright Elliot';
  static const String seniorPastorTitle = 'Senior Pastor';

  // Available Pastors for Dropdown
  static const List<String> availablePastors = [
    seniorPastorName,
    'Pastor John Doe',
    'Visiting Minister',
    'Guest Speaker',
  ];

  // Audio Player
  static const List<double> playbackSpeeds = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0
  ];
  static const double defaultPlaybackSpeed = 1.0;

  // Storage Keys
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyIsAdmin = 'is_admin';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyUserPhoto = 'user_photo';
  static const String keyFavorites = 'favorites';
  static const String keyCurrentStreak = 'current_streak';
  static const String keyLastListenDate = 'last_listen_date';

  // Animations
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);

  // Messages
  static const String addedToFavorites = 'Added to favorites ❤️';
  static const String removedFromFavorites = 'Removed from favorites';
  static const String shareMessage = 'Listen to this sermon on Rhemalize!';
}
