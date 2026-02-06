// lib/core/constants.dart

class AppConstants {
  // Twitch API (Public Client ID - sem OAuth)
  static const String twitchClientId = 'kimne78kx3ncx6brgo4mv6wki5h1ko';
  static const String twitchBaseUrl = 'https://api.twitch.tv/helix';
  static const String twitchGqlUrl = 'https://gql.twitch.tv/gql';
  
  // Kick API
  static const String kickBaseUrl = 'https://kick.com/api/v2';
  
  // App Config
  static const int maxStreamsInGrid = 4;
  static const String appName = 'Xtra-Neo';
}

class AppColors {
  static const int amoledBlack = 0xFF000000;
  static const int darkGrey = 0xFF121212;
  static const int cardGrey = 0xFF1E1E1E;
  static const int twitchPurple = 0xFF9146FF;
  static const int kickGreen = 0xFF53FC18;
  static const int accentRed = 0xFFFF4444;
}
