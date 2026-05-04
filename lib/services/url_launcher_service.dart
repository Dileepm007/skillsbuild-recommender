import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  /// Opens [url] in a new tab/external browser. Shows a snackbar if it fails.
  static Future<void> openCourseUrl(BuildContext context, String url) async {
    if (url.isEmpty) {
      _showError(context, 'No course URL available');
      return;
    }

    try {
      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        if (context.mounted) {
          _showError(context, 'Cannot open this URL');
        }
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to open course: $e');
      }
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
