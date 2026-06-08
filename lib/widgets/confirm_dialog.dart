import 'package:flutter/material.dart';

/// Shows a large, high-contrast confirmation dialog for risky actions
/// (spec §11.3). Returns true if the operator pressed 실행.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String message,
  String title = '확인',
  String confirmLabel = '실행',
  String cancelLabel = '취소',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 20)),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          SizedBox(
            height: 56,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel, style: const TextStyle(fontSize: 18)),
            ),
          ),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 28),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel, style: const TextStyle(fontSize: 18)),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
