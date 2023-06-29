import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleExclusive extends StatefulWidget {
  const RoleExclusive({
    super.key,
    required this.roles,
    required this.child,
  });

  final List<String> roles;
  final Widget child;

  @override
  State<RoleExclusive> createState() => _RoleExclusiveState();
}

class _RoleExclusiveState extends State<RoleExclusive> {
  late final List<String> roles = widget.roles;
  late final Widget child = widget.child;

  bool showChild = false;

  Future<void> showChildIfAppropriate() async {
    final prefs = await SharedPreferences.getInstance();

    final String? currentRole = prefs.getString("role");

    if (currentRole == null) return;

    setState(() {
      showChild = roles.contains(currentRole);
    });
  }

  @override
  void initState() {
    super.initState();

    showChildIfAppropriate();
  }

  @override
  Widget build(BuildContext context) {
    return showChild ? child : Container();
  }
}
