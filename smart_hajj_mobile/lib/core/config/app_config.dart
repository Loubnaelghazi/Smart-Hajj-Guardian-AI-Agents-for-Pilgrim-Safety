class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://smart-hajj-guardian-ai-agents-for.onrender.com',
  );
  static const pilgrimId = String.fromEnvironment(
    'PILGRIM_ID',
    defaultValue: 'demo-pilgrim-001',
  );
  static const groupId = String.fromEnvironment(
    'GROUP_ID',
    defaultValue: 'demo-group-001',
  );
  static const agencyId = String.fromEnvironment(
    'AGENCY_ID',
    defaultValue: 'demo-agency-001',
  );
  static const phone = String.fromEnvironment(
    'DEMO_PHONE',
    defaultValue: '+99999991000',
  );
  static const version = '1.0.0';
}
