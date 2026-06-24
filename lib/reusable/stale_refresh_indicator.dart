import 'dart:async';

import 'package:flutter/material.dart';

class StaleRefreshIndicator extends StatefulWidget implements PreferredSizeWidget {
  const StaleRefreshIndicator({
    super.key,
    required this.isRefreshing,
    required this.hasStaleData,
  });

  final bool isRefreshing;
  final bool hasStaleData;

  @override
  Size get preferredSize => const Size.fromHeight(4);

  @override
  State<StaleRefreshIndicator> createState() => _StaleRefreshIndicatorState();
}

class _StaleRefreshIndicatorState extends State<StaleRefreshIndicator> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(StaleRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRefreshing != widget.isRefreshing ||
        oldWidget.hasStaleData != widget.hasStaleData) {
      _schedule();
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (widget.isRefreshing && widget.hasStaleData) {
      _visible = false;
      _timer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _visible = true);
      });
    } else {
      _visible = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: Duration(milliseconds: _visible ? 1000 : 200),
        child: const LinearProgressIndicator(),
      ),
    );
  }
}