import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/app_exception.dart';
import '../models/domain.dart';
import '../repositories/repositories.dart';
import 'session_provider.dart';

class DashboardData {
  const DashboardData({
    this.pilgrim,
    this.group,
    this.guide,
    this.agency,
    this.zone,
    this.guardian,
    this.sosResult,
    this.incidents = const [],
    this.incidentsChecked = false,
    this.incidentError,
    this.error,
    this.refreshing = false,
    this.checking = false,
    this.sending = false,
    this.uncertainSos = false,
  });
  final Pilgrim? pilgrim;
  final GroupDetails? group;
  final Guide? guide;
  final Agency? agency;
  final SafeZone? zone;
  final GuardianResult? guardian, sosResult;
  final List<Incident> incidents;
  final bool incidentsChecked, refreshing, checking, sending, uncertainSos;
  final String? error, incidentError;
  Incident? get incident => incidents.isEmpty ? null : incidents.first;
  static const _keep = Object();
  DashboardData copy({
    Pilgrim? pilgrim,
    GroupDetails? group,
    Object? guide = _keep,
    Agency? agency,
    Object? zone = _keep,
    Object? guardian = _keep,
    GuardianResult? sosResult,
    List<Incident>? incidents,
    bool? incidentsChecked,
    Object? error = _keep,
    Object? incidentError = _keep,
    bool? refreshing,
    bool? checking,
    bool? sending,
    bool? uncertainSos,
  }) => DashboardData(
    pilgrim: pilgrim ?? this.pilgrim,
    group: group ?? this.group,
    guide: identical(guide, _keep) ? this.guide : guide as Guide?,
    agency: agency ?? this.agency,
    zone: identical(zone, _keep) ? this.zone : zone as SafeZone?,
    guardian: identical(guardian, _keep)
        ? this.guardian
        : guardian as GuardianResult?,
    sosResult: sosResult ?? this.sosResult,
    incidents: incidents ?? this.incidents,
    incidentsChecked: incidentsChecked ?? this.incidentsChecked,
    error: identical(error, _keep) ? this.error : error as String?,
    incidentError: identical(incidentError, _keep)
        ? this.incidentError
        : incidentError as String?,
    refreshing: refreshing ?? this.refreshing,
    checking: checking ?? this.checking,
    sending: sending ?? this.sending,
    uncertainSos: uncertainSos ?? this.uncertainSos,
  );
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardController, DashboardData>(
      DashboardController.new,
    );

class DashboardController extends AsyncNotifier<DashboardData> {
  late PilgrimSession _session;
  bool _polling = false;
  int _evaluationGeneration = 0;
  DateTime? _retryAfter;
  DashboardData get current => state.value ?? const DashboardData();
  String _message(Object e) => e is AppException
      ? e.message
      : 'This information could not be refreshed. Please try again.';
  void _set(DashboardData value) {
    if (ref.mounted) state = AsyncData(value);
  }

  @override
  Future<DashboardData> build() async {
    final session = await ref.watch(sessionProvider.future);
    if (session == null) return const DashboardData();
    _session = session;
    try {
      return await _trip(const DashboardData());
    } catch (e) {
      return DashboardData(error: _message(e));
    }
  }

  Future<DashboardData> _trip(DashboardData base) async {
    final api = ref.read(apiProvider);
    final pilgrim = await PilgrimRepository(api).get(_session.pilgrimId);
    final groupRepo = GroupRepository(api);
    final group = await groupRepo.get(pilgrim.groupId);
    final zone = await groupRepo.safeZone(pilgrim.groupId);
    final guide = group.guide ?? await groupRepo.guide(group.group.guideId);
    final agency = await groupRepo.agency(pilgrim.agencyId);
    return base.copy(
      pilgrim: pilgrim,
      group: group,
      zone: zone,
      guide: guide,
      agency: agency,
      error: null,
    );
  }

  Future<void> refresh({bool analyze = false}) async {
    if (current.refreshing ||
        current.sending ||
        current.checking ||
        state.isLoading) {
      return;
    }
    _set(current.copy(refreshing: true));
    ref.invalidate(healthProvider);
    try {
      final data = await _trip(current);
      if (!ref.mounted) return;
      _set(
        current.copy(
          pilgrim: data.pilgrim,
          group: data.group,
          zone: data.zone,
          guide: data.guide,
          agency: data.agency,
          error: null,
        ),
      );
      await poll(includeSafety: true);
    } catch (e) {
      _set(current.copy(error: _message(e)));
    } finally {
      _set(current.copy(refreshing: false));
    }
    if (analyze && ref.mounted && current.zone?.usable == true) await check();
  }

  Future<void> poll({bool includeSafety = false}) async {
    if (_polling ||
        current.sending ||
        state.isLoading ||
        (_retryAfter?.isAfter(DateTime.now()) ?? false)) {
      return;
    }
    _polling = true;
    final generation = _evaluationGeneration;
    try {
      final incidents = await IncidentRepository(ref.read(apiProvider))
          .active(_session.pilgrimId);
      if (!ref.mounted || generation != _evaluationGeneration) return;
      _set(
        current.copy(
          incidents: incidents,
          incidentsChecked: true,
          incidentError: null,
        ),
      );
      if (includeSafety && !current.checking) {
        final latest = await GuardianRepository(ref.read(apiProvider))
            .latest(current.pilgrim?.phone ?? _session.phoneNumber);
        if (!ref.mounted || generation != _evaluationGeneration) return;
        if (latest != null && latest.checkedAt != current.guardian?.checkedAt) {
          _set(current.copy(guardian: latest));
        }
      }
    } catch (e) {
      if (e is AppException && e.statusCode == 429) {
        _retryAfter = DateTime.now().add(const Duration(seconds: 30));
      }
      _set(current.copy(incidentError: _message(e)));
    } finally {
      _polling = false;
    }
  }

  Future<void> check({bool sos = false}) async {
    if (current.checking || current.sending || current.refreshing) return;
    _evaluationGeneration++;
    _set(current.copy(checking: !sos, sending: sos, error: null));
    try {
      final result = await GuardianRepository(ref.read(apiProvider)).analyze(
        current.pilgrim?.phone ?? _session.phoneNumber,
        current.zone,
        sos: sos,
      );
      if (!ref.mounted) return;
      final incident = result.incident;
      final incidents = [...current.incidents];
      if (incident != null &&
          incident.relevantTo(_session.pilgrimId) &&
          incident.active) {
        incidents.removeWhere((i) => i.id == incident.id);
        incidents.insert(0, incident);
      }
      _set(
        current.copy(
          guardian: result,
          sosResult: sos ? result : null,
          incidents: incidents,
          uncertainSos: false,
        ),
      );
    } catch (e) {
      _set(
        current.copy(
          error: _message(e),
          uncertainSos: sos && (e is! AppException || e.uncertain),
        ),
      );
    } finally {
      _set(current.copy(checking: false, sending: false));
    }
    if (ref.mounted) await poll();
  }
}
