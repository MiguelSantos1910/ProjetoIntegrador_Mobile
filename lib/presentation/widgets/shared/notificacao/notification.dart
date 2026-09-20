import 'package:flutter/material.dart';

enum NotificationType { info, success, warning, error }

class NotificationWidget extends StatelessWidget {
  final NotificationType type;
  final String title;
  final String description;
  final String name;
  final VoidCallback? onTap;

  const NotificationWidget({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    required this.name,
    this.onTap,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.info:
        return Icons.info_outline;

      case NotificationType.success:
        return Icons.check_circle_outline;

      case NotificationType.warning:
        return Icons.warning_amber_outlined;

      case NotificationType.error:
        return Icons.error_outline;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.info:
        return Colors.blue;

      case NotificationType.success:
        return Colors.green;

      case NotificationType.warning:
        return Colors.orange;

      case NotificationType.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(color: Colors.grey.shade200),
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Icon(icon, color: color, size: 24),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    name,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
