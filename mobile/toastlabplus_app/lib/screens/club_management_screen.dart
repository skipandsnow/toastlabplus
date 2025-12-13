import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';
import '../widgets/user_header.dart';
import 'club_detail_management_screen.dart';

class ClubManagementScreen extends StatefulWidget {
  const ClubManagementScreen({super.key});

  @override
  State<ClubManagementScreen> createState() => _ClubManagementScreenState();
}

class _ClubManagementScreenState extends State<ClubManagementScreen> {
  List<dynamic> _clubs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final member = authService.member;
      final role = member?['role'] ?? 'MEMBER';

      // Decide which clubs to list
      // For now, we fetch ALL clubs via public/common endpoint
      // and filter client-side based on role.
      final response = await http.get(
        Uri.parse('${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubsEndpoint}'),
        headers: authService.authHeaders,
      );

      if (response.statusCode == 200) {
        final allClubs = json.decode(response.body) as List<dynamic>;

        if (role == 'PLATFORM_ADMIN') {
          // Platform Admin sees all clubs
          _clubs = allClubs;
        } else if (role == 'CLUB_ADMIN') {
          // Club Admin sees only their own club
          final myClubId = member?['clubId'] as int?;
          if (myClubId != null) {
            _clubs = allClubs.where((c) => c['id'] == myClubId).toList();
          } else {
            _clubs = [];
          }
        } else {
          _clubs = []; // Should not happen if filtered at Home
        }
      } else {
        _error = 'Failed to load clubs: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error loading clubs: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: UserHeader(showBackButton: true),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select Club',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkWood,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadClubs, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_clubs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_late_outlined,
              size: 64,
              color: AppTheme.lightWood,
            ),
            const SizedBox(height: 16),
            Text(
              'No clubs found to manage.',
              style: TextStyle(color: AppTheme.lightWood, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _clubs.length,
      itemBuilder: (context, index) {
        final club = _clubs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: HandDrawnContainer(
            color: Colors.white,
            borderColor: AppTheme.dustyBlue,
            borderRadius: 16,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClubDetailManagementScreen(
                    clubId: club['id'] as int,
                    clubName: club['name'] ?? 'Club',
                  ),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.dustyBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.business, color: AppTheme.dustyBlue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        club['name'] ?? 'Unnamed Club',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkWood,
                        ),
                      ),
                      if (club['description'] != null)
                        Text(
                          club['description']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.lightWood,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.lightWood,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
