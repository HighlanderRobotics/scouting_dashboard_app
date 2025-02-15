enum ReefLevel { none, l1, l2, l3, l4 }

extension ReefLevelExtension on ReefLevel {
  String get localizedDescripton {
    switch (this) {
      case ReefLevel.none:
        return "None";
      case ReefLevel.l1:
        return "L1";
      case ReefLevel.l2:
        return "L2";
      case ReefLevel.l3:
        return "L3";
      case ReefLevel.l4:
        return "L4";
    }
  }
}
