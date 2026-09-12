import '../l10n/app_text.dart';
import '../l10n/app_copy.dart';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class SOSButton extends StatelessWidget {
  const SOSButton({super.key, required this.onConfirmed, this.busy = false});
  final VoidCallback onConfirmed;
  final bool busy;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: AppCopy.sosOpensEmergencyConfirmation.tr(context),
    child: SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.red,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
        onPressed: busy
            ? null
            : () async {
                final confirmed = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) => SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.sos, size: 48, color: AppColors.red),
                          const SizedBox(height: 16),
                          AppText(
                            AppCopy.sendAnEmergencyRequest,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          const AppText(
                            AppCopy.guardianWillRecordYourSosForYourGuide,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.red,
                              ),
                              child: const AppText(AppCopy.sendSosNow),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const AppText(AppCopy.cancel),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                if (confirmed == true && context.mounted) onConfirmed();
              },
        icon: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.emergency_outlined, size: 28),
        label: AppText(
          busy ? AppCopy.sendingEmergencyRequest : AppCopy.sosINeedHelp,
        ),
      ),
    ),
  );
}
