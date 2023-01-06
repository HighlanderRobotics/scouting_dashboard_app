import 'package:flutter/material.dart';

class ScrollablePageBody extends StatelessWidget {
  const ScrollablePageBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 16),
  });
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          SafeArea(
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          )
        ],
      ),
    );
  }
}
