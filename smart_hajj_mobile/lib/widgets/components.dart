import '../l10n/app_text.dart';
import '../l10n/app_copy.dart';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../models/domain.dart';

class GuardianCard extends StatelessWidget {
  const GuardianCard({
    super.key,
    required this.child,
    this.color = Colors.white,
  });
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Material(
      color: color,
      elevation: 1,
      shadowColor: AppColors.ink.withValues(alpha: .12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.ink.withValues(alpha: .05)),
      ),
      child: Padding(padding: const EdgeInsets.all(22), child: child),
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: AppText(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?trailing,
      ],
    ),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip(
    this.label, {
    super.key,
    this.color = AppColors.green,
    this.icon = Icons.circle,
  });
  final String label;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 7),
        Flexible(
          child: AppText(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}

class RiskBadge extends StatelessWidget {
  const RiskBadge(this.level, {super.key});
  final RiskLevel level;
  @override
  Widget build(BuildContext context) => StatusChip(
    AppStrings.of(context).risk(level),
    color: AppColors.risk(level),
    icon: level == RiskLevel.low
        ? Icons.verified_user_outlined
        : Icons.shield_outlined,
  );
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.icon});
  final String label, value;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 22, color: AppColors.muted),
          const SizedBox(width: 12),
        ],
        Expanded(child: AppText(label)),
        const SizedBox(width: 14),
        Flexible(
          child: AppText(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: AppCopy.loadingYourTrip.tr(context),
    child: Column(
      children: List.generate(
        3,
        (i) => Container(
          height: i == 0 ? 180 : 90,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE4EBE6),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.title,
    this.message, {
    super.key,
    this.icon = Icons.info_outline,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => GuardianCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.green, size: 30),
        const SizedBox(height: 12),
        AppText(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        AppText(message),
      ],
    ),
  );
}

class SafetyStatusCard extends StatelessWidget {
  const SafetyStatusCard({
    super.key,
    this.result,
    this.incident,
    this.hasZone = false,
    required this.onCheck,
  });
  final GuardianResult? result;
  final Incident? incident;
  final bool hasZone;
  final VoidCallback onCheck;
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final risk = incident?.risk.level == RiskLevel.critical
        ? RiskLevel.critical
        : result?.risk.level ?? RiskLevel.unknown;
    final old = result?.isOld(DateTime.now()) ?? false;
    final confirmedInside =
        hasZone &&
        !old &&
        result?.telecom.geofence == 'inside' &&
        result?.confidence.level != 'LOW' &&
        result?.hasErrors == false;
    final title = switch (risk) {
      RiskLevel.critical => AppCopy.criticalSafetyAlert,
      RiskLevel.high || RiskLevel.medium =>
        result?.telecom.geofence == 'outside'
            ? AppCopy.separationWarning
            : AppCopy.elevatedSafetyRisk,
      RiskLevel.low =>
        confirmedInside
            ? AppCopy.youReInYourGroupZone
            : AppCopy.stayConnectedToYourGroup,
      _ => s.noAnalysis,
    };
    final color = AppColors.risk(risk);
    return GuardianCard(
      color: Color.alphaBlend(color.withValues(alpha: .055), Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: RiskBadge(risk)),
              const SizedBox(width: 12),
              Icon(Icons.shield_outlined, size: 38, color: color),
            ],
          ),
          const SizedBox(height: 18),
          AppText(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          AppText(
            s.action(
              incident?.risk.level == RiskLevel.critical
                  ? incident?.action
                  : result?.action,
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (old) ...[const SizedBox(height: 10), AppText(s.stale)],
          if (result?.confidence.level == 'LOW') ...[
            const SizedBox(height: 10),
            AppText(s.limited),
          ],
          const SizedBox(height: 20),
          const Divider(),
          InfoRow(
            AppCopy.groupDistance,
            result?.telecom.distance == null
                ? s.unknown
                : '${result!.telecom.distance!.round()} m',
            icon: Icons.near_me_outlined,
          ),
          InfoRow(AppCopy.deviceNetwork, switch (result?.telecom.reachable) {
            true => AppCopy.reachable,
            false => AppCopy.unreachable,
            _ => s.unknown,
          }, icon: Icons.network_cell),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCheck,
              icon: const Icon(Icons.shield_outlined),
              label: AppText(incident == null ? s.safety : s.emergency),
            ),
          ),
        ],
      ),
    );
  }
}
