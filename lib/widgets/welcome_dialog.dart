import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class WelcomeDialog extends StatelessWidget {
  const WelcomeDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.appName),
      content: Text(l10n.appInspiration),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
