import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/meeting.dart';

/// Service for interacting with the MCP Server API
class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // ==================== Health Check ====================

  Future<Map<String, dynamic>> checkHealth() async {
    final response = await _client
        .get(
          Uri.parse('${ApiConfig.mcpServerBaseUrl}${ApiConfig.healthEndpoint}'),
        )
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Health check failed: ${response.statusCode}');
  }

  // ==================== Meetings ====================

  Future<List<Meeting>> getMeetings() async {
    final response = await _client
        .get(
          Uri.parse(
            '${ApiConfig.mcpServerBaseUrl}${ApiConfig.meetingsEndpoint}',
          ),
        )
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data
          .map((json) => Meeting.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load meetings: ${response.statusCode}');
  }

  Future<Meeting> getMeeting(int id) async {
    final response = await _client
        .get(
          Uri.parse(
            '${ApiConfig.mcpServerBaseUrl}${ApiConfig.meetingsEndpoint}/$id',
          ),
        )
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode == 200) {
      return Meeting.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to load meeting: ${response.statusCode}');
  }

  Future<Meeting> createMeeting(Meeting meeting) async {
    final response = await _client
        .post(
          Uri.parse(
            '${ApiConfig.mcpServerBaseUrl}${ApiConfig.meetingsEndpoint}',
          ),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(meeting.toJson()),
        )
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Meeting.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to create meeting: ${response.statusCode}');
  }

  // ==================== Clubs ====================

  Future<List<Map<String, dynamic>>> getClubs() async {
    final response = await _client
        .get(
          Uri.parse('${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubsEndpoint}'),
        )
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode == 200) {
      return (json.decode(response.body) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load clubs: ${response.statusCode}');
  }

  // ==================== Members ====================

  Future<List<Map<String, dynamic>>> getMembers() async {
    final response = await _client
        .get(
          Uri.parse(
            '${ApiConfig.mcpServerBaseUrl}${ApiConfig.membersEndpoint}',
          ),
        )
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode == 200) {
      return (json.decode(response.body) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load members: ${response.statusCode}');
  }

  // ==================== Roles ====================

  Future<List<Map<String, dynamic>>> getRoleAssignments(int meetingId) async {
    // Assuming endpoint follows REST convention or implementation plan
    // We might need to filter by meetingId if it's a general list, or specific endpoint
    // For now, let's use a query param
    final response = await _client
        .get(
          Uri.parse(
            '${ApiConfig.mcpServerBaseUrl}/api/role-assignments?meetingId=$meetingId',
          ),
        )
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode == 200) {
      return (json.decode(response.body) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    }
    // If endpoint returns empty list for 404, handle it, else throw
    if (response.statusCode == 404) return [];

    throw Exception('Failed to load role assignments: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createRoleAssignment(
    Map<String, dynamic> data,
  ) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.mcpServerBaseUrl}/api/role-assignments'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        )
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to sign up for role: ${response.statusCode}');
  }

  void dispose() {
    _client.close();
  }
}
