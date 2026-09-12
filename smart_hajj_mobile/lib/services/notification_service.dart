import '../models/domain.dart';

/// In-app alerts only. A push transport can be added without changing filtering.
class NotificationService {
  final Set<String> _seen = {};
  Incident? newAlert(List<Incident> incidents) {
    Incident? fresh;
    for (final incident in incidents) {
      if (_seen.add(
        '${incident.id}:${incident.status}:${incident.risk.level.name}',
      )) {
        fresh ??= incident;
      }
    }
    return fresh;
  }
}
