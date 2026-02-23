import 'package:flutter/material.dart';

class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 16),
    this.left = true,
    this.right = true,
    this.top = true,
    this.bottom = true,
  });
  final Widget child;
  final EdgeInsets padding;

  final bool left;
  final bool right;
  final bool top;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        left: left,
        right: right,
        top: top,
        bottom: bottom,
        child: Padding(
          padding: padding,
          child: LayoutBuilder(builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        constraints.maxWidth > 800 ? 800 : constraints.maxWidth,
                    maxHeight: constraints.maxHeight,
                  ),
                  child: child,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
