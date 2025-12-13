import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import 'admin_approval_screen.dart';

class AdminClubSelectScreen extends StatefulWidget {
  const AdminClubSelectScreen({super.key});

  @override
  State<AdminClubSelectScreen> createState() => _AdminClubSelectScreenState();
}

class _AdminClubSelectScreenState extends State<AdminClubSelectScreen> {
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
      final response = await http.get(
        Uri.parse('${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubsEndpoint}'),
        headers: authService.authHeaders,
      );

      if (response.statusCode == 200) {
        _clubs = json.decode(response.body) as List<dynamic>;
      } else {
        _error = 'Failed to load clubs';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Select Club to Approve',
          style: TextStyle(color: AppTheme.darkWood),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.darkWood),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : RefreshIndicator(
              onRefresh: _loadClubs,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _clubs.length,
                itemBuilder: (context, index) {
                  final club = _clubs[index];
                  return _buildClubCard(club);
                },
              ),
            ),
    );
  }

  Widget _buildClubCard(dynamic club) {
    final clubId = club['id'] as int;
    final clubName = club['name'] as String? ?? 'Unknown Club';
    final description = club['description'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Colors.white,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.dustyBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.groups, color: AppTheme.dustyBlue),
        ),
        title: Text(
          clubName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.darkWood,
          ),
        ),
        subtitle: description.isNotEmpty
            ? Text(
                description,
                style: TextStyle(color: AppTheme.lightWood, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.lightWood,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AdminApprovalScreen(clubId: clubId, clubName: clubName),
            ),
          );
        },
      ),
    );
  }
}
