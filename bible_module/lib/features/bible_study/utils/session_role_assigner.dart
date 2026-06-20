import '../models/bible_study_models.dart';

/// Assigns session roles based on total session count.
/// 
/// Session roles determine the structure and content depth of each session:
/// - foundation: Session 1 - establishes context, background, definitions
/// - development: Sessions 2-3 - builds on foundation
/// - depth: Middle sessions - core content, deepest exploration
/// - turningPoint: Mid-series hinge where understanding shifts
/// - integration: Session N-1 - connects all previous sessions
/// - application: Final session - legacy, lessons, personal response
class SessionRoleAssigner {
  /// Assigns roles for all sessions in a series.
  /// 
  /// Examples:
  /// - 1 session: [application] (single verse study - no foundation needed)
  /// - 2 sessions: [foundation, application]
  /// - 3 sessions: [foundation, development, application]
  /// - 5 sessions: [foundation, development, depth, integration, application]
  /// - 7 sessions: [foundation, development, depth, depth, turningPoint, integration, application]
  static List<SessionRole> assignRoles(int totalSessions) {
    if (totalSessions == 1) {
      // Single session is application-focused (single verse study)
      return [SessionRole.application];
    }

    if (totalSessions == 2) {
      return [
        SessionRole.foundation,
        SessionRole.application,
      ];
    }

    if (totalSessions == 3) {
      return [
        SessionRole.foundation,
        SessionRole.development,
        SessionRole.application,
      ];
    }

    if (totalSessions == 4) {
      return [
        SessionRole.foundation,
        SessionRole.development,
        SessionRole.depth,
        SessionRole.application,
      ];
    }

    if (totalSessions == 5) {
      return [
        SessionRole.foundation,
        SessionRole.development,
        SessionRole.depth,
        SessionRole.integration,
        SessionRole.application,
      ];
    }

    if (totalSessions == 6) {
      return [
        SessionRole.foundation,
        SessionRole.development,
        SessionRole.depth,
        SessionRole.depth,
        SessionRole.integration,
        SessionRole.application,
      ];
    }

    if (totalSessions == 7) {
      return [
        SessionRole.foundation,
        SessionRole.development,
        SessionRole.depth,
        SessionRole.depth,
        SessionRole.turningPoint,
        SessionRole.integration,
        SessionRole.application,
      ];
    }

    if (totalSessions == 8) {
      return [
        SessionRole.foundation,
        SessionRole.development,
        SessionRole.depth,
        SessionRole.depth,
        SessionRole.depth,
        SessionRole.turningPoint,
        SessionRole.integration,
        SessionRole.application,
      ];
    }

    if (totalSessions == 9) {
      return [
        SessionRole.foundation,
        SessionRole.development,
        SessionRole.depth,
        SessionRole.depth,
        SessionRole.depth,
        SessionRole.depth,
        SessionRole.turningPoint,
        SessionRole.integration,
        SessionRole.application,
      ];
    }

    if (totalSessions == 10) {
      return [
        SessionRole.foundation,
        SessionRole.development,
        SessionRole.depth,
        SessionRole.depth,
        SessionRole.depth,
        SessionRole.depth,
        SessionRole.depth,
        SessionRole.turningPoint,
        SessionRole.integration,
        SessionRole.application,
      ];
    }

    // For 14-day devotionals
    if (totalSessions == 14) {
      return [
        SessionRole.foundation,
        SessionRole.development,
        SessionRole.development,
        SessionRole.depth,
        SessionRole.depth,
        SessionRole.depth,
        SessionRole.turningPoint,
        SessionRole.depth,
        SessionRole.depth,
        SessionRole.turningPoint,
        SessionRole.depth,
        SessionRole.integration,
        SessionRole.integration,
        SessionRole.application,
      ];
    }

    // For any other count (11-13 or >14), use a general pattern
    // Foundation → Development → Depth (fill middle) → Turning Point → Integration → Application
    List<SessionRole> roles = [
      SessionRole.foundation,
      SessionRole.development,
    ];

    // Calculate how many depth sessions we need
    int depthCount = totalSessions - 5; // Subtract foundation, dev, turning, integration, application

    for (int i = 0; i < depthCount; i++) {
      roles.add(SessionRole.depth);
    }

    roles.addAll([
      SessionRole.turningPoint,
      SessionRole.integration,
      SessionRole.application,
    ]);

    return roles;
  }

  /// Gets the role for a specific session number.
  /// 
  /// Session numbers are 1-indexed.
  static SessionRole getRoleForSession(int sessionNumber, int totalSessions) {
    if (sessionNumber < 1 || sessionNumber > totalSessions) {
      throw ArgumentError(
        'Session number $sessionNumber out of range for $totalSessions total sessions',
      );
    }

    final roles = assignRoles(totalSessions);
    return roles[sessionNumber - 1];
  }

  /// Checks if a session is a foundation session (Session 1).
  static bool isFoundation(int sessionNumber) => sessionNumber == 1;

  /// Checks if a session is the final application session.
  static bool isApplication(int sessionNumber, int totalSessions) =>
      sessionNumber == totalSessions;

  /// Checks if a session should include introductory content.
  /// Only foundation sessions include full introductory content.
  static bool shouldIncludeIntroduction(int sessionNumber) =>
      isFoundation(sessionNumber);

  /// Checks if a session should include a previous session bridge.
  /// All sessions except Session 1 require a bridge.
  static bool requiresPreviousSessionBridge(int sessionNumber) =>
      sessionNumber > 1;
}
