import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/locale_provider.dart';

class LanguageSwitch extends ConsumerWidget {
  const LanguageSwitch({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return TextButton.icon(
      icon: const Icon(Icons.language, size: 20),
      label: Text(ar ? 'English' : 'العربية'),
      onPressed: () async {
        try {
          await ref.read(localeProvider.notifier).change(ar ? 'en' : 'ar');
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ar
                      ? 'تعذّر حفظ اللغة. حاول مجدداً.'
                      : 'Could not save language. Please retry.',
                ),
              ),
            );
          }
        }
      },
    );
  }
}
