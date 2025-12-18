enum EventType {
  shotSuccess,
  shotMiss,
  robotBecomesImmobile,
  robotBecomesMobile,
}

extension EventTypeExtension on EventType {
  int get numericalValue {
    return EventType.values.indexOf(this);
  }
}
