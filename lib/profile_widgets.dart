import 'package:flutter/material.dart';

// Compartido entre las pantallas principales.
class NotificationsMenuButton extends StatelessWidget {
  final List<String> notifications;

  const NotificationsMenuButton({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
      color: Colors.yellow[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[700]!, width: 1),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            'Notificaciones',
            style: TextStyle(
              color: Colors.grey[850],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const PopupMenuDivider(),
        for (final notif in notifications)
          PopupMenuItem(
            enabled: false,
            child: Text(
              notif,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class ProfileAvatarButton extends StatelessWidget {
  final String initials;
  final VoidCallback? onTap;

  const ProfileAvatarButton({super.key, required this.initials, this.onTap});

  @override
  Widget build(BuildContext context) {
    final avatar = Padding(
      padding: const EdgeInsets.all(8),
      child: CircleAvatar(
        backgroundColor: Colors.lime[400],
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}
