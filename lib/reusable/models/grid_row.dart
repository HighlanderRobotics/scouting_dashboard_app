enum GridRow {
  none,
  hybrid,
  middle,
  high,
}

extension GridRowExtension on GridRow {
  String get localizedDescripton {
    switch (this) {
      case GridRow.none:
        return "None";
      case GridRow.hybrid:
        return "Hybrid";
      case GridRow.middle:
        return "Middle";
      case GridRow.high:
        return "High";
    }
  }

  String get localizedDescriptonAbbreviated {
    switch (this) {
      case GridRow.none:
        return "None";
      case GridRow.hybrid:
        return "Low";
      case GridRow.middle:
        return "Mid";
      case GridRow.high:
        return "High";
    }
  }
}
