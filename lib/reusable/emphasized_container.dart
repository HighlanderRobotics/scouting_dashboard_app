import 'package:flutter/material.dart';

class EmphasizedContainer extends StatelessWidget {
  const EmphasizedContainer({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(10),
    this.radius = 10,
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Material(
        color: color ?? Theme.of(context).colorScheme.surfaceVariant,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
