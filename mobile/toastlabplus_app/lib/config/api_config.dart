/// API Configuration for ToastLabPlus
class ApiConfig {
  // MCP Server (Spring Boot) - for clubs, members, meetings, role assignments
  static const String mcpServerBaseUrl = String.fromEnvironment(
    'MCP_SERVER_URL',
    defaultValue: 'http://localhost:8080',
  );

  // Chat Backend (FastAPI) - for AI chat functionality
  static const String chatBackendBaseUrl = String.fromEnvironment(
    'CHAT_BACKEND_URL',
    defaultValue: 'http://localhost:8000',
  );

  // API Endpoints - MCP Server
  static const String healthEndpoint = '/api/health';
  static const String clubsEndpoint = '/api/clubs';
  static const String membersEndpoint = '/api/members';
  static const String meetingsEndpoint = '/api/meetings';
  static const String roleAssignmentsEndpoint = '/api/role-assignments';

  // Auth endpoints
  static const String authRegisterEndpoint = '/api/auth/register';
  static const String authLoginEndpoint = '/api/auth/login';
  static const String authMeEndpoint = '/api/auth/me';

  // Club membership endpoints
  static const String clubMembershipsEndpoint = '/api/club-memberships';

  // API Endpoints - Chat Backend
  static const String chatEndpoint = '/chat';
  static const String chatStreamEndpoint = '/chat/stream';
  static const String generateAgendaEndpoint = '/tools/generate-agenda';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
