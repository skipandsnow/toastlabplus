import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';
import '../services/api_service.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _roles = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    try {
      // Hardcoded meeting ID for demo/testing as we don't have full meeting selection flow yet
      // In production, this would be passed via constructor
      final roles = await _apiService.getRoleAssignments(1);
      setState(() {
        _roles = roles;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to mock data if API fails (for demo continuity if backend isn't populated)
      setState(() {
        _roles = [
          {'roleName': 'Timer', 'status': 'AVAILABLE'},
          {'roleName': 'Ah Counter', 'status': 'AVAILABLE'},
          {
            'roleName': 'Grammarian',
            'status': 'ASSIGNED',
            'memberName': 'Alice',
          },
          {'roleName': 'Speaker 1', 'status': 'ASSIGNED', 'memberName': 'Bob'},
          {'roleName': 'Evaluator 1', 'status': 'AVAILABLE'},
        ];
        _isLoading = false;
        // _errorMessage = e.toString(); // Uncomment to debug real errors
      });
    }
  }

  Future<void> _signUp(String roleName) async {
    try {
      await _apiService.createRoleAssignment({
        'meetingId': 1,
        'roleName': roleName,
        'memberId': 101, // Mock current user ID
      });

      // Optimistic update or refresh
      await _fetchRoles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Signed up for $roleName!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppTheme.sageGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign up: $e'),
            backgroundColor: Colors.red.shade300,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      body: CustomPaint(
        painter: CloudBackgroundPainter(),
        child: SafeArea(
          child: Column(
            children: [
              // Production App Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.lightWood.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.darkWood,
                          size: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Meeting Roles',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkWood,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44), // Balance
                  ],
                ),
              ),

              // Date Selector (Mockup)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.sageGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: AppTheme.sageGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'December 10, 2025',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.sageGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.sageGreen,
                        ),
                      )
                    : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade300),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _roles.length,
                        itemBuilder: (context, index) {
                          final role = _roles[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildRoleCard(
                              role['roleName'],
                              _getIconForRole(role['roleName']),
                              isAvailable: role['status'] == 'AVAILABLE',
                              isTaken: role['status'] == 'ASSIGNED',
                              user: role['memberName'],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForRole(String role) {
    if (role.contains('Timer')) return Icons.timer_outlined;
    if (role.contains('Ah')) return Icons.hearing_rounded;
    if (role.contains('Speaker')) return Icons.person;
    if (role.contains('Evaluator')) return Icons.rate_review_rounded;
    if (role.contains('Toastmaster')) return Icons.mic_external_on_rounded;
    return Icons.work_outline_rounded;
  }

  Widget _buildRoleCard(
    String role,
    IconData icon, {
    bool isAvailable = false,
    bool isTaken = false,
    String? user,
  }) {
    return HandDrawnContainer(
      color: Colors.white,
      borderColor: AppTheme.lightWood.withValues(alpha: 0.15), // Subtle border
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isTaken
                  ? AppTheme.lightWood.withValues(alpha: 0.1)
                  : AppTheme.softPeach.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isTaken ? AppTheme.lightWood : AppTheme.softPeach,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkWood,
                  ),
                ),
                if (isTaken)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      user ?? 'Unknown',
                      style: TextStyle(fontSize: 14, color: AppTheme.lightWood),
                    ),
                  ),
              ],
            ),
          ),
          if (isAvailable)
            InkWell(
              onTap: () => _signUp(role),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.sageGreen,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.sageGreen.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          if (isTaken)
            Icon(
              Icons.check_circle_rounded,
              color: AppTheme.lightWood.withValues(alpha: 0.5),
            ),
        ],
      ),
    );
  }
}
