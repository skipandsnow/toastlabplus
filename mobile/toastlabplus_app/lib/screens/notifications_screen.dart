import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(color: AppTheme.darkWood),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.darkWood),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HandDrawnContainer(
              padding: const EdgeInsets.all(32),
              color: AppTheme.warmWhite,
              borderColor: AppTheme.dustyBlue.withValues(alpha: 0.5),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 48,
                    color: AppTheme.dustyBlue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No New Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkWood,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We will let you know when something\nimportant happens.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.lightWood),
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
