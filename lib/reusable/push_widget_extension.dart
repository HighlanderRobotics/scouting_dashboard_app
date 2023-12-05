import 'package:flutter/material.dart';

extension PushWidget on NavigatorState {
  void pushWidget(Widget widget) {
    push(MaterialPageRoute(builder: (context) => widget));
  }

  void pushReplacementWidget(Widget widget) {
    pushReplacement(MaterialPageRoute(builder: (context) => widget));
  }
}
