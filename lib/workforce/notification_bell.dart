import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'notification_center.dart';
import 'notifications_screen.dart';

/// App-bar bell with a live unread badge. Tapping opens the feed.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationCenter.instance.unread,
      builder: (context, count, _) {
        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                count == 0
                    ? Icons.notifications_none_rounded
                    : Icons.notifications_rounded,
                color: AppColors.text,
              ),
              if (count > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.all(Radius.circular(9)),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'Notifications',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        );
      },
    );
  }
}