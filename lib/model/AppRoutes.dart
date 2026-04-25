class AppRoutes {
  static const String intro = '/intro';
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String changePassword = '/change-password';
  static const String settings = '/settings';
  static const String allScans = '/all-scans';

  /// Requires [AnalysisResultsArgs] as route arguments.
  static const String analysisResult = '/analysis-result';

  /// Requires [AnalysisConfirmationArgs] as route arguments.
  static const String analysisConfirmation = '/analysis-confirmation';
}
