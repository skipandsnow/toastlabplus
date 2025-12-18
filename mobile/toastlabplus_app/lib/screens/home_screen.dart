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
  String _searchQuery = '';
  String _clubManagementSearchQuery = '';

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

  Future<void> _showApplyDialog(
    BuildContext context,
    int clubId,
    String clubName,
  ) async {
    // Capture context-dependent objects before async gaps
    final authService = Provider.of<AuthService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.group_add, color: AppTheme.dustyBlue, size: 48),
            const SizedBox(height: 12),
            const Text('Join Club', textAlign: TextAlign.center),
          ],
        ),
        content: Text(
          'Apply to join "$clubName"?\n\nYour application will be reviewed by the club admin.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dustyBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubMembershipsEndpoint}',
        ),
        headers: authService.authHeaders,
        body: json.encode({'clubId': clubId}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Application submitted to "$clubName"'),
            backgroundColor: AppTheme.sageGreen,
          ),
        );
        await authService.getCurrentUser();
        _loadClubs();
      } else {
        final data = json.decode(response.body);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Application failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showCancelApplicationDialog(
    BuildContext context,
    int clubId,
    String clubName,
  ) async {
    // Capture context-dependent objects before async gaps
    final authService = Provider.of<AuthService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.orange, size: 48),
            const SizedBox(height: 12),
            const Text('Cancel Application', textAlign: TextAlign.center),
          ],
        ),
        content: Text(
          'Cancel your application to "$clubName"?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Application'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubMembershipsEndpoint}/club/$clubId',
        ),
        headers: authService.authHeaders,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Application to "$clubName" cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
        await authService.getCurrentUser();
        _loadClubs();
      } else {
        final data = json.decode(response.body);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Failed to cancel'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildAllClubsList(
    BuildContext context,
    Map<String, dynamic>? member,
  ) {
    final memberClubIds = member?['memberClubIds'] as List<dynamic>? ?? [];
    final pendingClubIds = member?['pendingClubIds'] as List<dynamic>? ?? [];

    if (_isLoadingClubs) {
      return const Center(child: CircularProgressIndicator());
    } else if (_clubs.isEmpty) {
      return HandDrawnContainer(
        color: Colors.white,
        borderColor: AppTheme.lightWood,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: Text("No clubs available.", textAlign: TextAlign.center),
          ),
        ),
      );
    }

    // Filter by search query
    final filteredClubs = _clubs.where((club) {
      if (_searchQuery.isEmpty) return true;
      final name = (club['name'] ?? '').toString().toLowerCase();
      final description = (club['description'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();

    // Sort clubs: Joined -> Pending -> Others
    filteredClubs.sort((a, b) {
      final aId = a['id'] as int;
      final bId = b['id'] as int;
      final aJoined = memberClubIds.contains(aId);
      final bJoined = memberClubIds.contains(bId);
      final aPending = pendingClubIds.contains(aId);
      final bPending = pendingClubIds.contains(bId);

      // Joined first
      if (aJoined && !bJoined) return -1;
      if (!aJoined && bJoined) return 1;
      // Then Pending
      if (aPending && !bPending) return -1;
      if (!aPending && bPending) return 1;
      // Then alphabetically
      return (a['name'] ?? '').compareTo(b['name'] ?? '');
    });

    return Column(
      children: [
        // Search box
        TextField(
          decoration: InputDecoration(
            hintText: 'Search clubs...',
            prefixIcon: Icon(Icons.search, color: AppTheme.lightWood),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: AppTheme.lightWood),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.lightWood.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.lightWood.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.sageGreen),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 16),
        if (filteredClubs.isEmpty)
          HandDrawnContainer(
            color: Colors.white,
            borderColor: AppTheme.lightWood,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: Text("No clubs found.", textAlign: TextAlign.center),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredClubs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final club = filteredClubs[index];
              final clubId = club['id'] as int;
              final isJoined = memberClubIds.contains(clubId);
              final isPending = pendingClubIds.contains(clubId);

              Color borderColor;
              if (isJoined) {
                borderColor = AppTheme.sageGreen;
              } else if (isPending) {
                borderColor = Colors.orange;
              } else {
                borderColor = AppTheme.lightWood.withValues(alpha: 0.5);
              }

              return HandDrawnContainer(
                color: Colors.white,
                borderColor: borderColor,
                borderRadius: 20,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClubPublicScreen(
                        clubId: clubId,
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
                          color: isJoined
                              ? AppTheme.sageGreen.withValues(alpha: 0.1)
                              : isPending
                              ? Colors.orange.withValues(alpha: 0.1)
                              : AppTheme.lightWood.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.groups,
                          color: isJoined
                              ? AppTheme.sageGreen
                              : isPending
                              ? Colors.orange
                              : AppTheme.lightWood,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              club['name'] ?? 'Club',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkWood,
                              ),
                            ),
                            if (club['description'] != null) ...[
                              const SizedBox(height: 4),
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status indicator / Apply button
                      if (isJoined)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.sageGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: AppTheme.sageGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Joined',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.sageGreen,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (isPending)
                        GestureDetector(
                          onTap: () {
                            _showCancelApplicationDialog(
                              context,
                              clubId,
                              club['name'] ?? 'Club',
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.hourglass_empty,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Applied',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dustyBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            _showApplyDialog(
                              context,
                              clubId,
                              club['name'] ?? 'Club',
                            );
                          },
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
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

                  // Search box for Club Management
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search clubs...',
                      prefixIcon: Icon(Icons.search, color: AppTheme.lightWood),
                      suffixIcon: _clubManagementSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppTheme.lightWood,
                              ),
                              onPressed: () => setState(
                                () => _clubManagementSearchQuery = '',
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppTheme.lightWood.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppTheme.lightWood.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.dustyBlue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => _clubManagementSearchQuery = value),
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
                    Builder(
                      builder: (context) {
                        final filteredClubs = _clubs.where((club) {
                          if (_clubManagementSearchQuery.isEmpty) return true;
                          final name = (club['name'] ?? '')
                              .toString()
                              .toLowerCase();
                          final description = (club['description'] ?? '')
                              .toString()
                              .toLowerCase();
                          final query = _clubManagementSearchQuery
                              .toLowerCase();
                          return name.contains(query) ||
                              description.contains(query);
                        }).toList();

                        if (filteredClubs.isEmpty) {
                          return HandDrawnContainer(
                            color: Colors.white,
                            borderColor: AppTheme.lightWood,
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text("No clubs found."),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredClubs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final club = filteredClubs[index];
                            return HandDrawnContainer(
                              color: Colors.white,
                              borderColor:
                                  AppTheme.dustyBlue, // Blue for management
                              borderRadius: 20,
                              onTap: () {
                                // Navigate to Club Detail MANAGEMENT Screen
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ClubDetailManagementScreen(
                                              clubId: club['id'] as int,
                                              clubName: club['name'] ?? 'Club',
                                            ),
                                      ),
                                    )
                                    .then((result) {
                                      // Refresh clubs list after returning (e.g., after delete)
                                      debugPrint(
                                        'HomeScreen: ClubDetailManagement returned result=$result',
                                      );
                                      if (result == true) _loadClubs();
                                    });
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
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ClubDetailManagementScreen(
                                              clubId: club['id'] as int,
                                              clubName: club['name'] ?? 'Club',
                                            ),
                                      ),
                                    )
                                    .then((result) {
                                      debugPrint(
                                        'HomeScreen (Club Admin): ClubDetailManagement returned result=$result',
                                      );
                                      if (result == true) _loadClubs();
                                    });
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

                    // --- ALL CLUBS SECTION FOR CLUB ADMIN ---
                    Text(
                      'All Clubs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkWood,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAllClubsList(context, member),
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
                        final memberClubIds =
                            member?['memberClubIds'] as List<dynamic>? ?? [];
                        // Filter joined clubs
                        final joinedClubs = _clubs
                            .where((c) => memberClubIds.contains(c['id']))
                            .toList();

                        if (joinedClubs.isEmpty) {
                          return HandDrawnContainer(
                            color: Colors.white,
                            borderColor: AppTheme.lightWood,
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  "You haven't joined any clubs yet.",
                                  textAlign: TextAlign.center,
                                ),
                              ),
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

                    // 2. All Clubs List
                    Text(
                      'All Clubs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkWood,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAllClubsList(context, member),
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
