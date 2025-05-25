class AppConfig {
  // Singleton instance
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // Development mode flag
  static bool _isDevelopment = false;

  // Getter for development mode
  static bool get isDevelopment => _isDevelopment;

  // Method to enable development mode
  static void enableDevelopmentMode() {
    _isDevelopment = true;
  }

  // Method to disable development mode
  static void disableDevelopmentMode() {
    _isDevelopment = false;
  }

  // Add other configuration settings here
} 