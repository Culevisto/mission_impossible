enum ServoId {
  A,
  B,
  C,
  D,
  E,
  F,
  G;

  String get code => name;

  String get pinName {
    switch (this) {
      case ServoId.A:
        return 'D8';
      case ServoId.B:
        return 'D9';
      case ServoId.C:
        return 'D10';
      case ServoId.D:
        return 'D11';
      case ServoId.E:
        return 'D12';
      case ServoId.F:
        return 'D6';
      case ServoId.G:
        return 'D7';
    }
  }

  String get jointName {
    switch (this) {
      case ServoId.A:
        return 'Base Rotator';
      case ServoId.B:
        return 'Shoulder Lift';
      case ServoId.C:
        return 'Elbow Lift';
      case ServoId.D:
        return 'Forearm Pitch';
      case ServoId.E:
        return 'Wrist Rotator';
      case ServoId.F:
        return 'Wrist Tilt / Aux';
      case ServoId.G:
        return 'Claw / Gripper';
    }
  }

  bool get isGripper => this == ServoId.G;
  bool get isClaw => this == ServoId.G;

  bool get defaultEnabled => true;

  static ServoId? fromString(String? value) {
    if (value == null) return null;
    final clean = value.trim().toUpperCase();
    for (final id in ServoId.values) {
      if (id.name == clean) {
        return id;
      }
    }
    return null;
  }
}
