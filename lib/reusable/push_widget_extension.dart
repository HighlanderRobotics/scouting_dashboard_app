import 'package:flutter/material.dart';

extension PushWidget on NavigatorState {
  void pushWidget(Widget widget) {
    push(MaterialPageRoute(builder: (context) => widget));
  }
}
