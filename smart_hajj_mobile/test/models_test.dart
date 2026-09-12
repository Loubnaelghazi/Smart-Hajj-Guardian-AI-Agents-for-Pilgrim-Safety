import 'package:flutter_test/flutter_test.dart';
import 'package:smart_hajj_mobile/models/domain.dart';
import 'package:smart_hajj_mobile/l10n/app_strings.dart';
import 'package:smart_hajj_mobile/repositories/repositories.dart';
import 'package:smart_hajj_mobile/services/notification_service.dart';

void main() {
  test('plain and enriched group contracts', () {
    expect(GroupDetails.fromJson({'id': 'g', 'name': 'A'}).group.id, 'g');
    final details = GroupDetails.fromJson({
      'group': {'id': 'g'},
      'guide': {'name': 'Ahmed'},
      'pilgrims_count': 20,
      'safe_zone': null,
    });
    expect(details.guide?.name, 'Ahmed');
    expect(details.count, 20);
    expect(details.safeZone, isNull);
  });
  test('safe-zone variants and malformed coordinates', () {
    expect(SafeZone.parse(null), isNull);
    expect(SafeZone.parse({'safe_zone': null}), isNull);
    expect(
      SafeZone.parse({'latitude': 200, 'longitude': 0, 'radius_m': 100})!
          .usable,
      isFalse,
    );
    final zone = SafeZone.parse({
      'safe_zone': {'latitude': 21.4, 'longitude': 39.8, 'radius_m': 250},
    })!;
    expect(zone.area, {'latitude': 21.4, 'longitude': 39.8, 'radius': 250});
  });
  test('real nested Guardian shape keeps risk and confidence separate', () {
    final result = GuardianResult.fromJson({
      'phone_number': '+1',
      'risk': {'score': 100, 'level': 'CRITICAL'},
      'confidence': {'score': 45, 'level': 'LOW'},
      'navigation': {'primary_action': 'WAIT_FOR_GUIDE'},
      'emergency': {
        'triggered': true,
        'qod_requested': true,
        'qod': {'qosStatus': 'REQUESTED', 'duration': 60},
      },
      'pilgrim_state': {
        'geofence_state': 'outside',
        'distance_from_group_m': 450,
        'reachability': {
          'reachabilityStatus': ['DATA'],
        },
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'congestion': {
          'data': [
            {'congestionLevel': 'HIGH'},
          ],
        },
      },
      'telecom_sources': {
        'reachability': {'source': 'stale-cache'},
      },
    });
    expect(result.risk.level, RiskLevel.critical);
    expect(result.confidence.score, 45);
    expect(result.telecom.reachable, isTrue);
    expect(result.telecom.congestion, 'HIGH');
    expect(result.telecom.stale, isTrue);
    expect(result.emergency.qod.requested, isTrue);
    expect(result.telecom.distance, 450);
    expect(result.isOld(DateTime.now()), isFalse);
  });
  test('unknown fields never become a safe risk or successful QoD', () {
    final result = GuardianResult.fromJson({
      'risk': {'level': 'NEW_VALUE'},
    });
    expect(result.risk.level, RiskLevel.unknown);
    expect(result.emergency.qod.requested, isFalse);
    expect(result.telecom.reachable, isNull);
    expect(result.isOld(DateTime.now()), isTrue);
    expect(
      const AppStrings().action('WAIT_FOR_GUIDE'),
      contains('Stay where you are'),
    );
    expect(
      const AppStrings().action('NEW_ACTION'),
      isNot(contains('NEW_ACTION')),
    );
  });
  test('only explicitly assigned active pilgrim incidents appear', () {
    final result = IncidentRepository.filter([
      {'id': 'mine', 'pilgrim_id': 'p', 'status': 'OPEN'},
      {'id': 'other', 'pilgrim_id': 'other', 'status': 'OPEN'},
      {'id': 'group', 'group_id': 'g', 'status': 'OPEN'},
      {'id': 'resolved', 'pilgrim_id': 'p', 'status': 'RESOLVED'},
      {'id': 'unknown', 'pilgrim_id': 'p', 'status': 'FUTURE'},
    ], 'p');
    expect(result.map((i) => i.id), ['mine']);
  });
  test('alerts deduplicate but acknowledgment changes notify', () {
    final notifications = NotificationService();
    final open = Incident.fromJson({'id': 'i', 'status': 'OPEN'});
    expect(notifications.newAlert([open]), open);
    expect(notifications.newAlert([open]), isNull);
    expect(
      notifications.newAlert([
        Incident.fromJson({'id': 'i', 'status': 'ACKNOWLEDGED'}),
      ]),
      isNotNull,
    );
  });
}
