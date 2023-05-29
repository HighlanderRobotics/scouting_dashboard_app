import 'package:flutter/material.dart';

class ScrollablePageBody extends StatefulWidget {
  const ScrollablePageBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 16),
  });
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  State<ScrollablePageBody> createState() => _ScrollablePageBodyState();
}

class _ScrollablePageBodyState extends State<ScrollablePageBody> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          final FocusScopeNode focusScope = FocusScope.of(context);
          if (notification.dragDetails != null &&
              focusScope.hasFocus &&
              !focusScope.hasPrimaryFocus) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
          return false;
        },
        child: SingleChildScrollView(
            child: SafeArea(
          child: Padding(
            padding: widget.padding,
            child: LayoutBuilder(builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth > 800
                          ? 800
                          : constraints.maxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: widget.children,
                    ),
                  ),
                ],
              );
            }),
          ),
        )),
      ),
    );
  }
}
