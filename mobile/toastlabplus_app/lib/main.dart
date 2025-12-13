import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/club_membership_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  await authService.init();

  runApp(
    ChangeNotifierProvider.value(
      value: authService,
      child: const ToastLabPlusApp(),
    ),
  );
}

class ToastLabPlusApp extends StatelessWidget {
  const ToastLabPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return MaterialApp(
          key: ValueKey(authService.isLoggedIn),
          title: 'ToastLabPlus',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: _buildHome(authService),
        );
      },
    );
  }

  Widget _buildHome(AuthService authService) {
    if (!authService.isLoggedIn) {
      return const LoginScreen();
    }

    final member = authService.member;
    final clubId = member?['clubId'];

    if (clubId == null) {
      return const ClubSelectionWrapper();
    }

    return const MainNavigationScreen();
  }
}

// Wrapper to show club membership screen with option to continue to main app
class ClubSelectionWrapper extends StatelessWidget {
  const ClubSelectionWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final member = authService.member;
    final userName = member?['name'] ?? 'User';
    final userRole = member?['role'] ?? 'MEMBER';

    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // User avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.dustyBlue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.dustyBlue, width: 2),
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dustyBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome, $userName!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkWood,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.sageGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  userRole == 'PLATFORM_ADMIN'
                      ? 'Platform Admin'
                      : userRole == 'CLUB_ADMIN'
                      ? 'Club Admin'
                      : 'Member',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.sageGreen,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'You haven\'t joined any club yet.\nPlease select a club to apply.',
                style: TextStyle(fontSize: 16, color: AppTheme.lightWood),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dustyBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClubMembershipScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Select Club',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MainNavigationScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Skip for now',
                    style: TextStyle(color: AppTheme.lightWood),
                  ),
                ),
              ),
              const Spacer(),
              // Logout button
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: TextButton.icon(
                  onPressed: () {
                    Provider.of<AuthService>(context, listen: false).logout();
                  },
                  icon: Icon(
                    Icons.logout,
                    color: Colors.red.shade400,
                    size: 18,
                  ),
                  label: Text(
                    'Logout',
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Main app with bottom navigation
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onChatSelected: () => setState(() => _currentIndex = 1),
        onSettingsSelected: () => setState(() => _currentIndex = 2),
      ),
      const ChatScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 65,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.darkWood.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined),
              _buildNavItem(
                1,
                Icons.chat_bubble_rounded,
                Icons.chat_bubble_outline_rounded,
              ),
              _buildNavItem(
                2,
                Icons.person_rounded,
                Icons.person_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
  ) {
    final isSelected = _currentIndex == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.sageGreen.withValues(alpha: 0.1)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSelected ? selectedIcon : unselectedIcon,
            color: isSelected
                ? AppTheme.sageGreen
                : AppTheme.lightWood.withValues(alpha: 0.6),
            size: 26,
          ),
        ),
      ),
    );
  }
}
