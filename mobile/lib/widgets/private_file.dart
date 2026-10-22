import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';
import '../services/student_auth_service.dart';

Future<void> openPrivateFile(BuildContext context, Future<String> Function() createUrl) async {
  try {
    final url = await createUrl();
    if (!context.mounted) return;
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Your file is ready'), content: const Text('Open the file using this temporary link.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
        Link(uri: Uri.parse(url), target: LinkTarget.blank, builder: (_, followLink) =>
          TextButton(onPressed: followLink, child: const Text('Open file')))]));
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(StudentAuthService.errorMessage(error))));
    }
  }
}
