enum ClimbingChallenge {
  didntClimb,
  failedClimb,
  bottomBar,
  middleBar,
  highBar,
  traversal
}

extension ClimbingChallengeExtension on ClimbingChallenge {
  String get name {
    switch (this) {
      case ClimbingChallenge.didntClimb:
        return "Didn't climb";
      case ClimbingChallenge.failedClimb:
        return "Failed climb";
      case ClimbingChallenge.bottomBar:
        return "Bottom bar";
      case ClimbingChallenge.middleBar:
        return "Middle bar";
      case ClimbingChallenge.highBar:
        return "High bar";
      case ClimbingChallenge.traversal:
        return "Traversal";
      default:
        return "Unknown";
    }
  }

  static ClimbingChallenge fromName(String name) =>
      ClimbingChallenge.values.firstWhere((element) => element.name == name);
}
