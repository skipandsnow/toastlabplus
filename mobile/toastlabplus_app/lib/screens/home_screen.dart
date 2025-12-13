import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';
import '../services/auth_service.dart';

import 'club_detail_management_screen.dart';

import 'club_public_screen.dart';
import 'create_club_screen.dart';
import '../widgets/user_header.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onChatSelected;
  final VoidCallback onSettingsSelected;

  const HomeScreen({
    super.key,
    required this.onChatSelected,
    required this.onSettingsSelected,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _clubs = [];
  bool _isLoadingClubs = false;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    setState(() => _isLoadingClubs = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.get(
        Uri.parse('${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubsEndpoint}'),
        headers: authService.authHeaders,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _clubs = json.decode(response.body) as List<dynamic>;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading clubs: $e');
    } finally {
      if (mounted) setState(() => _isLoadingClubs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final member = authService.member;
    final role = member?['role'] ?? 'MEMBER';
    final adminClubIds = member?['adminClubIds'] as List<dynamic>? ?? [];

    final isPlatformAdmin = role == 'PLATFORM_ADMIN';
    final isClubAdmin = adminClubIds.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      body: CustomPaint(
        painter: CloudBackgroundPainter(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                UserHeader(onMembershipChanged: _loadClubs),

                // PLATFORM ADMIN DASHBOARD
                if (isPlatformAdmin) ...[
                  const SizedBox(height: 32),
                  // Create Club Block
                  HandDrawnContainer(
                    color: AppTheme.sageGreen.withValues(alpha: 0.1),
                    borderColor: AppTheme.sageGreen,
                    borderRadius: 24,
                    padding: const EdgeInsets.all(24),
                    onTap: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => const CreateClubScreen(),
                            ),
                          )
                          .then((result) {
                            if (result == true) _loadClubs();
                          });
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.sageGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_business_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Club',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.darkWood,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Start a new branch',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.lightWood,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.sageGreen,
                          size: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // CLUB MANAGEMENT LIST (Replaces standard list and menu)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Club Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkWood,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings, color: AppTheme.dustyBlue),
                        onPressed: widget.onSettingsSelected,
                        tooltip: 'Settings',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_isLoadingClubs)
                    const Center(child: CircularProgressIndicator())
                  else if (_clubs.isEmpty)
                    HandDrawnContainer(
                      color: Colors.white,
                      borderColor: AppTheme.lightWood,
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("No clubs found."),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _clubs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final club = _clubs[index];
                        return HandDrawnContainer(
                          color: Colors.white,
                          borderColor:
                              AppTheme.dustyBlue, // Blue for management
                          borderRadius: 20,
                          onTap: () {
                            // Navigate to Club Detail MANAGEMENT Screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ClubDetailManagementScreen(
                                  clubId: club['id'] as int,
                                  clubName: club['name'] ?? 'Club',
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dustyBlue.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.admin_panel_settings_rounded,
                                    color: AppTheme.dustyBlue,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        club['name'] ?? 'Club',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.darkWood,
                                        ),
                                      ),
                                      if (club['description'] != null)
                                        Text(
                                          club['description'],
                                          style: TextStyle(
                                            color: AppTheme.lightWood,
                                            fontSize: 12,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.edit_rounded,
                                  size: 20,
                                  color: AppTheme.dustyBlue,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
                // Start public list logic directly (previous block removed)

                // Public CLUBS list and MENU (Only if NOT Platform Admin)
                // Platform Admin has its own list above.
                if (!isPlatformAdmin) ...[
                  const SizedBox(height: 32),

                  if (isClubAdmin) ...[
                    // --- MANAGED CLUBS SECTION ---
                    Text(
                      'Managed Clubs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkWood,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        // Find clubs I manage (using adminClubIds list)
                        final adminClubIds =
                            member?['adminClubIds'] as List<dynamic>? ?? [];
                        final managedClubs = _clubs
                            .where((c) => adminClubIds.contains(c['id']))
                            .toList();

                        if (managedClubs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("No managed clubs."),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: managedClubs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final club = managedClubs[index];
                            return HandDrawnContainer(
                              color: Colors.white,
                              borderColor: AppTheme.dustyBlue,
                              borderRadius: 20,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ClubDetailManagementScreen(
                                      clubId: club['id'] as int,
                                      clubName: club['name'] ?? 'Club',
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.dustyBlue.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.admin_panel_settings_rounded,
                                        color: AppTheme.dustyBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.dustyBlue
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Club Admin',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.dustyBlue,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            club['name'] ?? 'Club',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.darkWood,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.edit_rounded,
                                      color: AppTheme.dustyBlue,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // --- JOINED CLUBS SECTION ---
                    Text(
                      'Joined Clubs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkWood,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        // Find clubs I am a member of (Using same clubId for now as 1-club limit)
                        final myClubId = member?['clubId'];
                        final joinedClubs = _clubs
                            .where((c) => c['id'] == myClubId)
                            .toList();

                        if (joinedClubs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("No joined clubs."),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: joinedClubs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final club = joinedClubs[index];
                            return HandDrawnContainer(
                              color: Colors.white,
                              borderColor: AppTheme.sageGreen,
                              borderRadius: 20,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ClubPublicScreen(
                                      clubId: club['id'] as int,
                                      clubName: club['name'] ?? 'Club',
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.sageGreen.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.groups,
                                        color: AppTheme.sageGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        club['name'] ?? 'Club',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.darkWood,
                                        ),
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
                      },
                    ),
                  ] else ...[
                    // --- REGULAR MEMBER VIEW ---

                    // 1. My Joined Clubs
                    Text(
                      'My Clubs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkWood,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final myClubId = member?['clubId'];
                        // Filter joined clubs
                        final joinedClubs = _clubs
                            .where((c) => c['id'] == myClubId)
                            .toList();

                        if (joinedClubs.isEmpty) {
                          return HandDrawnContainer(
                            color: Colors.white,
                            borderColor: AppTheme.lightWood,
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text("You haven't joined any clubs yet."),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: joinedClubs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final club = joinedClubs[index];
                            return HandDrawnContainer(
                              color: Colors.white,
                              borderColor: AppTheme.sageGreen,
                              borderRadius: 20,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ClubPublicScreen(
                                      clubId: club['id'] as int,
                                      clubName: club['name'] ?? 'Club',
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.sageGreen.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.star,
                                        color: AppTheme.sageGreen,
                                      ), // Star for my club
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        club['name'] ?? 'Club',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.darkWood,
                                        ),
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
                      },
                    ),

                    const SizedBox(height: 32),

                    // 2. All Clubs List (Excluding Joined)
                    Text(
                      'All Clubs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkWood,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final myClubId = member?['clubId'];
                        // Filter to exclude joined clubs
                        final otherClubs = _clubs
                            .where((c) => c['id'] != myClubId)
                            .toList();

                        if (_isLoadingClubs) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (otherClubs.isEmpty) {
                          return HandDrawnContainer(
                            color: Colors.white,
                            borderColor: AppTheme.lightWood,
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text("No other clubs available."),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: otherClubs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final club = otherClubs[index];
                            return HandDrawnContainer(
                              color: Colors.white,
                              borderColor: AppTheme.sageGreen.withValues(
                                alpha: 0.5,
                              ), // Softer border for general list
                              borderRadius: 20,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ClubPublicScreen(
                                      clubId: club['id'] as int,
                                      clubName: club['name'] ?? 'Club',
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.sageGreen.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.groups,
                                        color: AppTheme.sageGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            club['name'] ?? 'Club',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.darkWood,
                                            ),
                                          ),
                                          if (club['description'] != null)
                                            Text(
                                              club['description'],
                                              style: TextStyle(
                                                color: AppTheme.lightWood,
                                                fontSize: 12,
                                              ),
                                              maxLines: 2,
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
                      },
                    ),
                  ],
                ],
                // Add lots of space for scrolling to work comfortably
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
