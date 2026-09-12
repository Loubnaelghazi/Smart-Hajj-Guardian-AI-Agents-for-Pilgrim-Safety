import '../l10n/app_text.dart';
import '../l10n/app_copy.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../models/domain.dart';
import '../providers/dashboard_provider.dart';
import '../providers/session_provider.dart';
import '../services/incident_polling_service.dart';
import '../services/notification_service.dart';
import '../widgets/components.dart';
import '../widgets/guardian_brand.dart';
import '../widgets/sos_button.dart';
import '../widgets/phone_monitoring_card.dart';
import '../widgets/incident_briefing.dart';

class TripShell extends ConsumerStatefulWidget {
  const TripShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;
  @override
  ConsumerState<TripShell> createState() => _TripShellState();
}

class _TripShellState extends ConsumerState<TripShell>
    with WidgetsBindingObserver {
  late final IncidentPollingService _poller;
  final _notifications = NotificationService();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poller = IncidentPollingService(
      onTick: (tick) {
        if (!mounted) return;
        final controller = ref.read(dashboardProvider.notifier);
        if (tick > 0 && tick % 6 == 0) {
          unawaited(controller.refresh());
        } else {
          unawaited(
            controller.poll(
              includeSafety: tick % 2 == 0 && widget.path != '/profile',
            ),
          );
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _poller.start();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _poller.start();
    } else {
      _poller.stop();
    }
  }

  @override
  void dispose() {
    _poller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final dashboard = ref.watch(dashboardProvider);
    final d = dashboard.value;
    ref.listen(dashboardProvider, (previous, next) {
      final alert = _notifications.newAlert(next.value?.incidents ?? []);
      if (alert == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            alert.risk.level == RiskLevel.critical
                ? AppCopy.criticalGuardianAlertViewYourEmergencyStatus
                : AppCopy.aNewGuardianAlertIsAvailable,
          ),
          action: SnackBarAction(
            label: AppCopy.view.tr(context),
            onPressed: () => context.go('/emergency'),
          ),
        ),
      );
    });
    final index = switch (widget.path) {
      '/group' || '/safe-zone' || '/return' => 1,
      '/safety' || '/emergency' => 2,
      '/profile' => 3,
      _ => 0,
    };
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: widget.child),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 4),
              child: PhoneMonitoringCard(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.path != '/emergency')
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
              child: SOSButton(
                busy: d == null || d.sending || d.checking || d.refreshing,
                onConfirmed: () {
                  context.go('/emergency');
                  unawaited(
                    ref.read(dashboardProvider.notifier).check(sos: true),
                  );
                },
              ),
            ),
          NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) =>
                context.go(['/home', '/group', '/safety', '/profile'][i]),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: s.home,
              ),
              NavigationDestination(
                icon: const Icon(Icons.groups_outlined),
                selectedIcon: const Icon(Icons.groups),
                label: s.group,
              ),
              NavigationDestination(
                icon: const Icon(Icons.shield_outlined),
                selectedIcon: const Icon(Icons.shield),
                label: s.safety,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: s.profile,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TripScreen extends ConsumerWidget {
  const TripScreen({super.key, required this.page});
  final String page;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);
    final controller = ref.read(dashboardProvider.notifier);
    final s = AppStrings.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: RefreshIndicator(
          onRefresh: () => controller.refresh(analyze: page == 'home'),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
            children: [
              GuardianBrand(
                trailing: IconButton.filledTonal(
                  tooltip: AppCopy.refreshTrip.tr(context),
                  onPressed: data.value?.refreshing == true
                      ? null
                      : () => controller.refresh(),
                  icon: const Icon(Icons.refresh),
                ),
              ),
              const SizedBox(height: 26),
              if (data.isLoading)
                const LoadingSkeleton()
              else if (data.hasError)
                EmptyState(
                  AppCopy.tripUnavailable,
                  AppCopy.pleasePullDownToRetry,
                )
              else
                ..._content(
                  context,
                  ref,
                  data.value ?? const DashboardData(),
                  s,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    WidgetRef ref,
    DashboardData d,
    AppStrings s,
  ) {
    return [
      if (d.refreshing || d.checking) ...[
        const LinearProgressIndicator(),
        const SizedBox(height: 16),
      ],
      if (d.error != null || d.incidentError != null) ...[
        GuardianCard(
          color: const Color(0xFFFFF1DE),
          child: AppText(
            d.error ?? d.incidentError!,
            semanticsLabel: d.error ?? d.incidentError!,
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (d.incident != null &&
          page != 'emergency' &&
          page != 'home' &&
          page != 'safety') ...[
        GuardianCard(
          color: const Color(0xFFFCE9E8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                AppCopy.guardianAlert,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              AppText(s.action(d.incident!.action)),
              TextButton(
                onPressed: () => context.go('/emergency'),
                child: const AppText(AppCopy.viewEmergencyStatus),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
      ...switch (page) {
        'home' => _home(context, ref, d, s),
        'group' => _group(context, d, s),
        'safety' => _safety(context, ref, d, s),
        'safe-zone' => [
          AppText(
            AppCopy.groupSafeZone,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          _zone(context, d, s),
        ],
        'return' => _return(context, ref, d, s),
        'emergency' => _emergency(context, ref, d, s),
        _ => _profile(context, ref, d, s),
      },
    ];
  }

  List<Widget> _home(
    BuildContext context,
    WidgetRef ref,
    DashboardData d,
    AppStrings s,
  ) => [
    JourneyHero(
      name: d.pilgrim?.name ?? 'pilgrim',
      group: d.group?.group.name ?? AppCopy.yourHajjGroup,
      onGroup: () => context.go('/group'),
    ),
    const SizedBox(height: 24),
    if (d.incidentsChecked &&
        d.incident == null &&
        d.incidentError == null) ...[
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 18,
              color: AppColors.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppText(
                AppCopy.noActiveSafetyAlerts,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    ],
    SafetyStatusCard(
      result: d.guardian,
      incident: d.incident,
      hasZone: d.zone?.usable == true,
      onCheck: () => context.go(d.incident == null ? '/safety' : '/emergency'),
    ),
    const SizedBox(height: 18),
    FilledButton.icon(
      onPressed: () => context.go('/return'),
      icon: const Icon(Icons.near_me_outlined),
      label: AppText(s.returnToGroup),
    ),
    SectionHeader(
      AppCopy.yourPeople,
      trailing: TextButton(
        onPressed: () => context.go('/group'),
        child: const AppText(AppCopy.viewGroup),
      ),
    ),
    _guide(context, d, s),
    const SectionHeader(AppCopy.yourMeetingPoint),
    _zone(context, d, s),
  ];
  Widget _guide(BuildContext context, DashboardData d, AppStrings s) =>
      GuardianCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFFE3F0E9),
                  child: Icon(Icons.support_agent, color: AppColors.green),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        AppCopy.yourGuide,
                        style: TextStyle(fontSize: 11, letterSpacing: 1.2),
                      ),
                      AppText(
                        d.guide?.name ?? s.noGuide,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (d.guide?.phone != null) ...[
              const SizedBox(height: 12),
              AppText(d.guide!.phone!),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _launch(
                    context,
                    Uri(scheme: 'tel', path: d.guide!.phone!),
                  ),
                  icon: const Icon(Icons.call_outlined),
                  label: AppText(s.contact),
                ),
              ),
            ],
          ],
        ),
      );
  Widget _zone(BuildContext context, DashboardData d, AppStrings s) {
    final zone = d.zone;
    if (zone == null) {
      return EmptyState(
        AppCopy.noGroupSafeZone,
        s.noZone,
        icon: Icons.location_off_outlined,
      );
    }
    final verified = !(d.guardian?.isOld(DateTime.now()) ?? true);
    final state = verified ? d.guardian?.telecom.geofence : null;
    return GuardianCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: AppColors.green,
            size: 30,
          ),
          const SizedBox(height: 12),
          AppText(
            zone.name ?? AppCopy.groupMeetingPoint,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          InfoRow(
            AppCopy.zoneRadius,
            zone.radius == null ? s.unknown : '${zone.radius!.round()} m',
          ),
          InfoRow(AppCopy.lastVerifiedStatus, switch (state) {
            'inside' => AppCopy.insideSafeZone,
            'outside' => AppCopy.outsideSafeZone,
            _ => AppCopy.notVerified,
          }),
          if (zone.hasCoordinates)
            TextButton.icon(
              onPressed: () => _maps(context, zone),
              icon: const Icon(Icons.open_in_new),
              label: const AppText(AppCopy.openInMaps),
            ),
        ],
      ),
    );
  }

  List<Widget> _group(BuildContext context, DashboardData d, AppStrings s) => [
    AppText(
      d.group?.group.name ?? AppCopy.yourGroup,
      style: Theme.of(context).textTheme.headlineLarge,
    ),
    const SizedBox(height: 10),
    AppText(
      d.group?.group.description ?? AppCopy.stayConnectedThroughoutYourJourney,
    ),
    const SizedBox(height: 20),
    GuardianCard(
      child: Column(
        children: [
          InfoRow(
            AppCopy.pilgrimsInYourGroup,
            d.group?.count?.toString() ?? s.unknown,
            icon: Icons.groups_outlined,
          ),
          InfoRow(AppCopy.agency, d.agency?.name ?? s.unknown),
          InfoRow(
            AppCopy.yourAlerts,
            d.incidentsChecked
                ? '${d.incidents.length} active'
                : AppCopy.notChecked,
          ),
        ],
      ),
    ),
    const SectionHeader(AppCopy.hereToHelp),
    _guide(context, d, s),
    const SectionHeader(AppCopy.groupSafeZone),
    _zone(context, d, s),
    const SizedBox(height: 18),
    FilledButton.icon(
      onPressed: () => context.go('/return'),
      icon: const Icon(Icons.near_me_outlined),
      label: AppText(s.returnToGroup),
    ),
  ];
  List<Widget> _safety(
    BuildContext context,
    WidgetRef ref,
    DashboardData d,
    AppStrings s,
  ) {
    final g = d.guardian;
    return [
      AppText(
        AppCopy.yourSafetyNatAGlance,
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 22),
      SafetyStatusCard(
        result: g,
        incident: d.incident,
        hasZone: d.zone?.usable == true,
        onCheck: () {
          if (d.incident != null) {
            context.go('/emergency');
          } else {
            unawaited(ref.read(dashboardProvider.notifier).check());
          }
        },
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: d.checking || d.sending || d.refreshing
            ? null
            : () => ref.read(dashboardProvider.notifier).check(),
        icon: const Icon(Icons.refresh),
        label: AppText(d.checking ? AppCopy.checkingSafety : s.check),
      ),
      if (d.zone == null) ...[const SizedBox(height: 16), AppText(s.noZone)],
      const SectionHeader(AppCopy.safetyDetails),
      GuardianCard(
        child: Column(
          children: [
            InfoRow(
              AppCopy.riskScore,
              g?.risk.score == null
                  ? s.unknown
                  : '${g!.risk.score!.round()} / 100',
            ),
            InfoRow(
              AppCopy.safetyConfidence,
              g?.confidence.score == null
                  ? s.unknown
                  : '${g!.confidence.score!.round()}% · ${g.confidence.level ?? ''}',
            ),
            InfoRow(AppCopy.lastChecked, _time(g?.checkedAt)),
            if (g?.confidence.stale == true || g?.telecom.stale == true)
              AppText(s.stale),
            if (g?.hasErrors == true) AppText(s.limited),
          ],
        ),
      ),
      const SectionHeader(AppCopy.networkSignals),
      GuardianCard(
        child: Column(
          children: [
            InfoRow(
              AppCopy.locationVerification,
              d.zone == null
                  ? AppCopy.noGroupZone
                  : switch (g?.telecom.geofence) {
                      'inside' => AppCopy.insideGroupZone,
                      'outside' => AppCopy.outsideGroupZone,
                      _ => s.unknown,
                    },
              icon: Icons.location_on_outlined,
            ),
            InfoRow(AppCopy.deviceReachability, switch (g?.telecom.reachable) {
              true => AppCopy.reachable,
              false => AppCopy.unreachable,
              _ => s.unknown,
            }, icon: Icons.network_cell),
            InfoRow(
              AppCopy.congestion,
              g?.telecom.congestion ?? s.unknown,
              icon: Icons.cell_tower,
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const AppText(AppCopy.signalFreshness),
              children: [
                for (final entry
                    in g?.telecom.sources.entries ??
                        <MapEntry<String, dynamic>>[])
                  InfoRow(_sourceName(entry.key), _source(entry.value)),
                if (g?.telecom.sources.isEmpty ?? true) AppText(s.unknown),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const AppText(AppCopy.signalSources),
              childrenPadding: const EdgeInsets.only(bottom: 12),
              children: [
                const AppText(AppCopy.signalSourcesExplanation),
                if (object(
                      g?.telecom.sources['congestion'],
                    )['simulator_device'] !=
                    null) ...[
                  const SizedBox(height: 12),
                  const AppText(AppCopy.simulatorCongestion),
                ],
                const SizedBox(height: 12),
                const AppText(AppCopy.distanceSource),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _return(
    BuildContext context,
    WidgetRef ref,
    DashboardData d,
    AppStrings s,
  ) {
    final wait =
        d.incident?.risk.level == RiskLevel.critical ||
        d.guardian?.action == 'WAIT_FOR_GUIDE';
    return [
      AppText(
        wait ? AppCopy.stayWhereYouAre : s.returnToGroup,
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 14),
      AppText(
        wait
            ? s.action('WAIT_FOR_GUIDE')
            : s.action(
                d.guardian?.action == 'CONTINUE_MONITORING'
                    ? 'RETURN_TO_GROUP'
                    : d.guardian?.action,
              ),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 22),
      GuardianCard(
        child: InfoRow(
          AppCopy.distanceFromGroup,
          d.guardian?.telecom.distance == null
              ? s.unknown
              : '${d.guardian!.telecom.distance!.round()} m',
          icon: Icons.near_me_outlined,
        ),
      ),
      const SectionHeader(AppCopy.contactYourGuide),
      _guide(context, d, s),
      const SectionHeader(AppCopy.meetingPoint),
      _zone(context, d, s),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: d.checking || d.sending
            ? null
            : () => ref.read(dashboardProvider.notifier).check(),
        icon: const Icon(Icons.refresh),
        label: AppText(s.check),
      ),
    ];
  }

  List<Widget> _emergency(
    BuildContext context,
    WidgetRef ref,
    DashboardData d,
    AppStrings s,
  ) {
    final incident = d.incident;
    final sent = d.sosResult?.emergency.triggered == true;
    final qod = d.sosResult?.emergency.qod;
    final expired =
        qod?.expiresAt?.isBefore(DateTime.now()) == true ||
        (qod?.duration != null &&
            d.sosResult?.emergency.triggeredAt != null &&
            DateTime.now()
                    .difference(d.sosResult!.emergency.triggeredAt!)
                    .inSeconds >
                qod!.duration!);
    final priority = expired
        ? AppCopy.requestPeriodEnded
        : qod?.requested == true
        ? (qod?.status == 'AVAILABLE' || qod?.status == 'ACTIVE'
              ? AppCopy.activeAtLastResponse
              : AppCopy.requested)
        : AppCopy.notConfirmed;
    return [
      AppText(s.emergency, style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 20),
      GuardianCard(
        color: const Color(0xFFFCE9E8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.sos, size: 46, color: AppColors.red),
            const SizedBox(height: 16),
            AppText(
              d.sending
                  ? AppCopy.sendingEmergencyRequest
                  : d.uncertainSos
                  ? AppCopy.requestNotConfirmed
                  : incident != null
                  ? AppCopy.emergencyActive
                  : sent
                  ? AppCopy.sosResponseReceived
                  : AppCopy.noActiveEmergencyConfirmed,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            AppText(
              incident != null
                  ? s.action(incident.action)
                  : AppCopy.ifYouNeedUrgentHelpContactYourGuide,
            ),
            if (d.sending) ...[
              const SizedBox(height: 18),
              const LinearProgressIndicator(),
            ],
            if (sent) ...[
              const SizedBox(height: 12),
              const AppText(AppCopy.emergencyRequestSentToGuardian),
            ],
            if (incident != null) ...[
              const SizedBox(height: 12),
              AppText(
                incident.status == 'ACKNOWLEDGED'
                    ? AppCopy.yourGuideOrAgencyHasAcknowledgedThisAlert
                    : AppCopy.yourRequestIsRecordedInTheAgencyCommand,
              ),
              const SizedBox(height: 14),
              RiskBadge(incident.risk.level),
              InfoRow(AppCopy.reference, incident.id),
            ],
            if (sent && incident == null)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: AppText(
                  AppCopy.noActiveIncidentIsCurrentlyConfirmedRefreshStatus,
                ),
              ),
            InfoRow(AppCopy.networkPriority, priority),
            if (qod?.profile != null)
              ExpansionTile(
                title: const AppText(AppCopy.networkPriorityDetails),
                children: [
                  InfoRow(AppCopy.profile, qod!.profile!),
                  if (qod.duration != null)
                    InfoRow(
                      AppCopy.duration,
                      '${qod.duration!.round()} seconds',
                    ),
                ],
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _guide(context, d, s),
      const SizedBox(height: 18),
      OutlinedButton.icon(
        onPressed: d.sending
            ? null
            : () => ref
                  .read(dashboardProvider.notifier)
                  .poll(includeSafety: true),
        icon: const Icon(Icons.refresh),
        label: const AppText(AppCopy.refreshEmergencyStatus),
      ),
      if (incident != null) ...[
        const SizedBox(height: 16),
        IncidentBriefing(incident: incident),
      ],
      if (!d.sending && incident == null) ...[
        const SizedBox(height: 18),
        SOSButton(
          busy: d.checking || d.refreshing,
          onConfirmed: () =>
              ref.read(dashboardProvider.notifier).check(sos: true),
        ),
      ],
      if (incident != null && incident.type != 'SOS') ...[
        const SizedBox(height: 18),
        SOSButton(
          busy: d.sending || d.checking || d.refreshing,
          onConfirmed: () =>
              ref.read(dashboardProvider.notifier).check(sos: true),
        ),
      ],
    ];
  }

  List<Widget> _profile(
    BuildContext context,
    WidgetRef ref,
    DashboardData d,
    AppStrings s,
  ) => [
    AppText(
      AppCopy.yourHajjJourney,
      style: Theme.of(context).textTheme.headlineLarge,
    ),
    const SizedBox(height: 22),
    GuardianCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Color(0xFFE3F0E9),
            child: Icon(Icons.person_outline, size: 36, color: AppColors.green),
          ),
          const SizedBox(height: 16),
          AppText(
            d.pilgrim?.name ?? AppCopy.pilgrim,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          const StatusChip(AppCopy.demoSession),
          const SizedBox(height: 12),
          InfoRow(AppCopy.phone, d.pilgrim?.phone ?? s.unknown),
          InfoRow(AppCopy.nationality, d.pilgrim?.nationality ?? s.unknown),
          InfoRow(AppCopy.agency, d.agency?.name ?? s.unknown),
          InfoRow(AppCopy.group, d.group?.group.name ?? s.unknown),
          InfoRow(AppCopy.guide, d.guide?.name ?? s.unknown),
        ],
      ),
    ),
    const SectionHeader(AppCopy.aboutGuardian),
    GuardianCard(
      child: Column(
        children: [
          InfoRow(AppCopy.applicationVersion, AppConfig.version),
          InfoRow(
            AppCopy.backendConnection,
            ref.watch(healthProvider).value == true
                ? AppCopy.connected
                : AppCopy.unavailable,
          ),
          const AppText(AppCopy.inAppAlertsUpdateWhileTheAppIs),
        ],
      ),
    ),
    const SizedBox(height: 24),
    OutlinedButton.icon(
      onPressed: d.sending
          ? null
          : () async {
              try {
                await ref.read(sessionProvider.notifier).logout();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: AppText(
                        AppCopy.couldNotClearYourSessionPleaseTryAgain,
                      ),
                    ),
                  );
                }
              }
            },
      icon: const Icon(Icons.logout),
      label: const AppText(AppCopy.leaveDemoSession),
    ),
  ];
  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      /* The user receives the same actionable fallback below. */
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(AppCopy.noCompatibleAppCouldBeOpenedUseThe),
        ),
      );
    }
  }

  void _maps(BuildContext context, SafeZone zone) => unawaited(
    _launch(
      context,
      Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '${zone.latitude},${zone.longitude}',
      }),
    ),
  );
  String _time(DateTime? time) {
    if (time == null) return AppCopy.notChecked;
    final seconds = DateTime.now().difference(time).inSeconds;
    if (seconds < 60) return AppCopy.lessThanAMinuteAgo;
    if (seconds < 3600) return '${seconds ~/ 60} minutes ago';
    final local = time.toLocal();
    return '${local.day}/${local.month} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _sourceName(String key) => switch (key) {
    'location_verification' => AppCopy.location,
    'reachability' => AppCopy.reachability,
    'congestion' => AppCopy.congestion,
    _ => AppCopy.otherSignal,
  };
  String _source(dynamic raw) {
    final j = object(raw);
    final label = switch (j['source']) {
      'live-nokia' => AppCopy.liveAtLastCheck,
      'cache' => AppCopy.cached,
      'stale-cache' => AppCopy.outdatedCache,
      _ => AppCopy.notAvailable,
    };
    return j['cache_age_seconds'] is num
        ? '$label · ${(j['cache_age_seconds'] as num).round()}s old'
        : label;
  }
}
