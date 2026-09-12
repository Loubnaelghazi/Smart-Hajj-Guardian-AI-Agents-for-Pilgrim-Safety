import '../l10n/app_text.dart';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../l10n/app_copy.dart';
import 'language_switch.dart';

class GuardianBrand extends StatelessWidget {
  const GuardianBrand({super.key, this.trailing});
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.shield_outlined,
          color: Color(0xFF81D9B6),
          size: 26,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              AppStrings.of(context).brand,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 16,
                letterSpacing: -.3,
              ),
            ),
            AppText(
              AppStrings.of(context).tagline,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
      const LanguageSwitch(),
      ?trailing,
    ],
  );
}

class JourneyHero extends StatelessWidget {
  const JourneyHero({
    super.key,
    required this.name,
    required this.group,
    required this.onGroup,
  });
  final String name, group;
  final VoidCallback onGroup;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0C252C), Color(0xFF123F38)],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: .12),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -42,
          top: -56,
          child: ExcludeSemantics(
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .07),
                  width: 30,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    color: Color(0xFF9BD8BF),
                    size: 17,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: AppText(
                      AppCopy.companionEyebrow,
                      style: TextStyle(
                        color: Color(0xFFB9E5D1),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppText(
                'Hello, $name',
                style: const TextStyle(
                  fontSize: 30,
                  height: 1.13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.8,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Material(
                color: Colors.white.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: onGroup,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          color: Color(0xFFB9E5D1),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppText(
                            group,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Color(0xFFB9E5D1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
