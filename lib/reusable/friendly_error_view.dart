import 'package:flutter/material.dart';

class FriendlyErrorView extends StatelessWidget {
  const FriendlyErrorView({
    super.key,
    this.errorMessage,
    this.onRetry,
    this.retryLabel = "Retry",
  });

  final String? errorMessage;
  final dynamic Function()? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ":(",
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 10),
          Text(
            "An ${errorMessage == null ? "unknown " : ""}error has occured.",
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 5),
            Text(
              errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: Text(retryLabel)),
          ]
        ],
      ),
    );
  }
}
