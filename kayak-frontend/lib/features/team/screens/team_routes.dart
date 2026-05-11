/// Team route constants
library;

/// Team management route constants
class TeamRoutes {
  TeamRoutes._();

  /// Team list page
  static const String list = '/teams';

  /// Team detail page
  static const String detail = '/teams/:id';

  /// Helper to build detail path
  static String detailPath(String teamId) => '/teams/$teamId';
}
