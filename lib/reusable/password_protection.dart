import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

void passwordProtected(
  BuildContext context,
  String correctPassword,
  dynamic Function() onCorrectPassword,
) {
  showDialog(
      context: context,
      builder: (context) =>
          PasswordPromptDialog(onSubmit: (String submittedPassword) {
            if (submittedPassword == correctPassword) {
              onCorrectPassword();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  "Incorrect password",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                behavior: SnackBarBehavior.floating,
              ));
            }
          }));
}

class PasswordPromptDialog extends StatefulWidget {
  const PasswordPromptDialog({
    super.key,
    required this.onSubmit,
  });

  final dynamic Function(String submittedPassword) onSubmit;

  @override
  State<PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<PasswordPromptDialog> {
  String inputValue = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Password required"),
      content: TextField(
        onChanged: (value) {
          setState(() {
            inputValue = value;
          });
        },
        decoration: const InputDecoration(
          filled: true,
          label: Text("Password"),
        ),
        obscureText: true,
        autocorrect: false,
      ),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onSubmit(inputValue);
          },
          child: const Text("Submit"),
        ),
      ],
    );
  }
}
