/// App version information
class AppVersion {
  static const String version = '0.1.7';
  static const String buildNumber = '1';
  static const String fullVersion = '$version+$buildNumber';

  /// Short display format: "v2.1.0"
  static const String displayVersion = 'v$version';

  /// Full display format: "Version 2.1.0 (Build 1)"
  static const String displayFull = 'Version $version (Build $buildNumber)';

  /// Copyright notice
  static const String copyright = '© 2025 ToastLab+. All rights reserved.';
}
