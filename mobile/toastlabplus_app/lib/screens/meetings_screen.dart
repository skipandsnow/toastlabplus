import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      appBar: AppBar(
        title: Text(
          'Meetings',
          style: TextStyle(
            color: AppTheme.darkWood,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 60,
              color: AppTheme.sageGreen.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Under Construction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkWood,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This feature will be available soon.',
              style: TextStyle(color: AppTheme.lightWood),
            ),
          ],
        ),
      ),
    );
  }
}
