typedef Json = Map<String, dynamic>;
Json object(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
String? string(dynamic value) =>
    value is String && value.isNotEmpty ? value : null;
double? number(dynamic value) {
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  return parsed?.isFinite == true ? parsed : null;
}

DateTime? date(dynamic value) => DateTime.tryParse('$value');
List<Json> objects(dynamic value) =>
    value is List ? value.whereType<Map>().map(object).toList() : [];

enum RiskLevel {
  low,
  medium,
  high,
  critical,
  unknown;

  static RiskLevel parse(dynamic value) => switch ('$value'.toUpperCase()) {
    'LOW' => low,
    'MEDIUM' => medium,
    'HIGH' => high,
    'CRITICAL' => critical,
    _ => unknown,
  };
}

class RiskStatus {
  RiskStatus.fromJson(Json j)
    : score = number(j['score']),
      level = RiskLevel.parse(j['level']);
  final double? score;
  final RiskLevel level;
}

class ConfidenceStatus {
  ConfidenceStatus.fromJson(Json j)
    : score = number(j['score']),
      level = string(j['level']),
      stale =
          j['stale_signals'] is List && (j['stale_signals'] as List).isNotEmpty;
  final double? score;
  final String? level;
  final bool stale;
}

class Agency {
  Agency.fromJson(Json j)
    : id = string(j['id']) ?? '',
      name = string(j['name']);
  final String id;
  final String? name;
}

class Guide {
  Guide.fromJson(Json j)
    : id = string(j['id']) ?? '',
      name = string(j['name']),
      phone = string(j['phone_number']);
  final String id;
  final String? name, phone;
}

class Pilgrim {
  Pilgrim.fromJson(Json j)
    : id = string(j['id']) ?? '',
      groupId = string(j['group_id']) ?? '',
      agencyId = string(j['agency_id']) ?? '',
      name = string(j['name']),
      phone = string(j['phone_number']),
      nationality = string(j['nationality']);
  final String id, groupId, agencyId;
  final String? name, phone, nationality;
}

class Group {
  Group.fromJson(Json j)
    : id = string(j['id']) ?? '',
      name = string(j['name']),
      guideId = string(j['guide_id']),
      description = string(j['description']);
  final String id;
  final String? name, guideId, description;
}

class GroupDetails {
  GroupDetails.fromJson(Json j)
    : group = Group.fromJson(j.containsKey('group') ? object(j['group']) : j),
      guide = j['guide'] is Map ? Guide.fromJson(object(j['guide'])) : null,
      safeZone = SafeZone.parse(j['safe_zone']),
      count = number(j['pilgrims_count'])?.toInt();
  final Group group;
  final Guide? guide;
  final SafeZone? safeZone;
  final int? count;
}

class SafeZone {
  SafeZone.fromJson(Json j)
    : name = string(j['name']),
      latitude = number(j['latitude']),
      longitude = number(j['longitude']),
      radius = number(j['radius_m']);
  final String? name;
  final double? latitude, longitude, radius;
  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude!.abs() <= 90 &&
      longitude!.abs() <= 180;
  bool get usable => hasCoordinates && radius != null && radius! > 0;
  Json get area => {
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius!.round(),
  };
  static SafeZone? parse(dynamic raw) {
    if (raw is! Map) return null;
    final j = object(raw);
    if (j.containsKey('safe_zone')) return parse(j['safe_zone']);
    return j.isEmpty ? null : SafeZone.fromJson(j);
  }
}

class Incident {
  Incident.fromJson(Json j)
    : id = string(j['id']) ?? '',
      pilgrimId = string(j['pilgrim_id']),
      groupId = string(j['group_id']),
      status = string(j['status']),
      type = string(j['type']),
      risk = RiskStatus.fromJson({
        'score': j['risk_score'],
        'level': j['risk_level'],
      }),
      action = string(j['navigation_action']),
      createdAt = date(j['created_at']);
  final String id;
  final String? pilgrimId, groupId, status, type, action;
  final RiskStatus risk;
  final DateTime? createdAt;
  bool get active => status == 'OPEN' || status == 'ACKNOWLEDGED';
  bool relevantTo(String id) => id.isNotEmpty && pilgrimId == id;
}

class TelecomStatus {
  TelecomStatus.fromJson(Json state, this.sources)
    : geofence = string(state['geofence_state']),
      reachable = _reach(object(state['reachability'])),
      congestion = _congestion(object(state['congestion'])['data']),
      distance = number(state['distance_from_group_m']);
  final String? geofence, congestion;
  final bool? reachable;
  final double? distance;
  final Json sources;
  bool get stale =>
      sources.values.any((s) => object(s)['source'] == 'stale-cache');
  static bool? _reach(Json j) {
    if (j['reachable'] is bool) return j['reachable'] as bool;
    final status = j['reachabilityStatus'];
    if (status is List) {
      return status.isEmpty
          ? false
          : status.any((s) => s == 'DATA' || s == 'SMS');
    }
    return switch (status) {
      'REACHABLE' => true,
      'UNREACHABLE' => false,
      _ => null,
    };
  }

  static String? _congestion(dynamic data) {
    for (final item in objects(data)) {
      if (string(item['congestionLevel']) != null) {
        return string(item['congestionLevel']);
      }
    }
    return string(object(data)['congestionLevel']);
  }
}

class QoDResult {
  QoDResult.fromJson(Json j, this.requested)
    : status = string(j['qosStatus']) ?? string(j['status']),
      profile = string(j['qosProfile']),
      duration = number(j['duration']),
      expiresAt = date(j['expiresAt']);
  final bool requested;
  final String? status, profile;
  final double? duration;
  final DateTime? expiresAt;
}

class EmergencyResult {
  EmergencyResult.fromJson(Json j)
    : triggered = j['triggered'] == true,
      triggeredAt = date(j['triggered_at']),
      qod = QoDResult.fromJson(object(j['qod']), j['qod_requested'] == true);
  final bool triggered;
  final DateTime? triggeredAt;
  final QoDResult qod;
}

class GuardianResult {
  GuardianResult.fromJson(Json j)
    : phone = string(j['phone_number']),
      risk = RiskStatus.fromJson(object(j['risk'])),
      confidence = ConfidenceStatus.fromJson(object(j['confidence'])),
      action = string(object(j['navigation'])['primary_action']),
      guidance = string(object(j['navigation'])['guidance']),
      telecom = TelecomStatus.fromJson(
        object(j['pilgrim_state']),
        object(
          j['telecom_sources'] ?? object(j['pilgrim_state'])['telecom_sources'],
        ),
      ),
      emergency = EmergencyResult.fromJson(object(j['emergency'])),
      incident = j['incident'] is Map
          ? Incident.fromJson(object(j['incident']))
          : null,
      checkedAt = date(object(j['pilgrim_state'])['updated_at']),
      hasErrors =
          j['telecom_errors'] is List &&
          (j['telecom_errors'] as List).isNotEmpty;
  final String? phone, action, guidance;
  final RiskStatus risk;
  final ConfidenceStatus confidence;
  final TelecomStatus telecom;
  final EmergencyResult emergency;
  final Incident? incident;
  final DateTime? checkedAt;
  final bool hasErrors;
  bool isOld(DateTime now) =>
      checkedAt == null || now.difference(checkedAt!).inSeconds > 120;
  factory GuardianResult.fromState(Json j) => GuardianResult.fromJson({
    'phone_number': j['phone_number'],
    'risk': j['risk'],
    'navigation': j['navigation'],
    'pilgrim_state': j,
    'telecom_sources': j['telecom_sources'],
  });
}

class PilgrimSession {
  const PilgrimSession({
    required this.pilgrimId,
    required this.groupId,
    required this.agencyId,
    required this.phoneNumber,
  });
  factory PilgrimSession.fromJson(Json j) => PilgrimSession(
    pilgrimId: string(j['pilgrim_id']) ?? '',
    groupId: string(j['group_id']) ?? '',
    agencyId: string(j['agency_id']) ?? '',
    phoneNumber: string(j['phone_number']) ?? '',
  );
  final String pilgrimId, groupId, agencyId, phoneNumber;
  bool get valid =>
      [pilgrimId, groupId, agencyId, phoneNumber].every((s) => s.isNotEmpty);
  Json toJson() => {
    'pilgrim_id': pilgrimId,
    'group_id': groupId,
    'agency_id': agencyId,
    'phone_number': phoneNumber,
  };
}
