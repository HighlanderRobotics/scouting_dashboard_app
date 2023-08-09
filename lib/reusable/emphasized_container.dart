import 'package:flutter/material.dart';

class EmphasizedContainer extends StatelessWidget {
  const EmphasizedContainer({
    super.key,
    required this.child,
    this.color,
  });

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color ?? Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: child,
      ),
    );
  }
}
