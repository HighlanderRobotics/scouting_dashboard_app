import 'package:flutter/material.dart';

class EmphasizedContainer extends StatelessWidget {
  const EmphasizedContainer({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(10),
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color ?? Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
