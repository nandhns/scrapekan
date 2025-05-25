import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ScraPekanAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userRole;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const ScraPekanAppBar({
    Key? key,
    required this.userRole,
    this.onNotificationTap,
    this.onProfileTap,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('ScraPekan - ${userRole.toUpperCase()}'),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined),
          onPressed: onNotificationTap,
        ),
        IconButton(
          icon: Icon(Icons.person_outline),
          onPressed: onProfileTap,
        ),
        SizedBox(width: 8),
      ],
    );
  }
} 