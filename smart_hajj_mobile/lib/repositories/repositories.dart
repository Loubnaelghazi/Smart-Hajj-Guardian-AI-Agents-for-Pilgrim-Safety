import '../core/network/app_exception.dart';
import '../core/network/dio_client.dart';
import '../models/domain.dart';

String segment(String value) => Uri.encodeComponent(value);

class PilgrimRepository {
  PilgrimRepository(this.api);
  final ApiClient api;
  Future<Pilgrim> findByPhone(String phone) async {
    final entered = phone.trim();
    if (entered.isEmpty || entered.length > 64) {
      throw const AppException(
        'Enter the phone number registered by your agency.',
      );
    }
    try {
      final pilgrim = Pilgrim.fromJson(
        object(
          await api.post('/api/pilgrims/lookup', {'phone_number': entered}),
        ),
      );
      if (pilgrim.id.isEmpty ||
          pilgrim.groupId.isEmpty ||
          pilgrim.agencyId.isEmpty ||
          pilgrim.phone != entered) {
        throw const AppException(
          'Your pilgrim profile is incomplete or does not match this phone. Please contact your agency.',
        );
      }
      return pilgrim;
    } on AppException catch (error) {
      if (error.statusCode == 404) {
        throw const AppException(
          'No pilgrim is registered with this phone number. Check the number, including the country code, or contact your agency.',
          statusCode: 404,
        );
      }
      rethrow;
    }
  }

  Future<Pilgrim> get(String id) async {
    final pilgrim = Pilgrim.fromJson(
      object(await api.get('/api/pilgrims/${segment(id)}')),
    );
    if (pilgrim.id != id || pilgrim.phone == null || pilgrim.groupId.isEmpty) {
      throw const AppException(
        'Your pilgrim profile is incomplete. Please contact your agency.',
      );
    }
    return pilgrim;
  }
}

class GroupRepository {
  GroupRepository(this.api);
  final ApiClient api;
  Future<GroupDetails> get(String id) async => GroupDetails.fromJson(
    object(await api.get('/api/groups/${segment(id)}')),
  );
  Future<Guide?> guide(String? id) async {
    if (id == null) return null;
    try {
      return Guide.fromJson(
        object(await api.get('/api/guides/${segment(id)}')),
      );
    } on AppException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<SafeZone?> safeZone(String id) async {
    try {
      return SafeZone.parse(
        await api.get('/api/groups/${segment(id)}/safe-zone'),
      );
    } on AppException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Agency> agency(String id) async =>
      Agency.fromJson(object(await api.get('/api/agencies/${segment(id)}')));
}

class IncidentRepository {
  IncidentRepository(this.api);
  final ApiClient api;
  static List<Incident> filter(dynamic raw, String pilgrimId) {
    final list = raw is List ? raw : object(raw)['incidents'];
    if (list is! List || list.any((item) => item is! Map)) {
      throw const AppException(
        'Guardian alerts could not be read. Please refresh.',
      );
    }
    final incidents = objects(list)
        .map(Incident.fromJson)
        .where((i) => i.relevantTo(pilgrimId) && i.active)
        .toList();
    incidents.sort((a, b) {
      int priority(RiskLevel level) =>
          level == RiskLevel.unknown ? -1 : level.index;
      final risk = priority(b.risk.level).compareTo(priority(a.risk.level));
      return risk != 0
          ? risk
          : (b.createdAt ?? DateTime(1970)).compareTo(
              a.createdAt ?? DateTime(1970),
            );
    });
    return incidents;
  }

  Future<List<Incident>> active(String id) async =>
      filter(await api.get('/api/incidents/active'), id);
}

class GuardianRepository {
  GuardianRepository(this.api);
  final ApiClient api;
  Future<GuardianResult?> latest(String phone) async {
    final response = object(await api.get('/api/pilgrims'));
    for (final state in objects(response['pilgrims'])) {
      if (state['phone_number'] == phone && state['risk'] is Map) {
        return GuardianResult.fromState(state);
      }
    }
    return null;
  }

  Future<GuardianResult> analyze(
    String phone,
    SafeZone? zone, {
    bool sos = false,
  }) async {
    // Without a group zone the backend uses its simulator default area. Only
    // SOS may use that fallback; it must not establish a group-safe claim.
    if (!sos && (zone == null || !zone.usable)) {
      throw const AppException(
        'Your agency has not configured a group safe zone yet. You can still send SOS or call your guide.',
      );
    }
    final body = <String, dynamic>{
      'phone_number': phone,
      if (zone?.usable == true) 'safe_area': zone!.area,
    };
    final result = GuardianResult.fromJson(
      object(
        await api.post(
          sos ? '/api/guardian/sos' : '/api/guardian/analyze',
          body,
        ),
      ),
    );
    if (result.phone != phone || result.risk.level == RiskLevel.unknown) {
      throw const AppException(
        'Guardian returned incomplete safety information. Please refresh.',
        uncertain: true,
      );
    }
    return result;
  }
}
