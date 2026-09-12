import '../l10n/app_text.dart';
import '../l10n/app_copy.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/network/app_exception.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../providers/session_provider.dart';
import '../widgets/components.dart';
import '../widgets/guardian_brand.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 72,
                color: AppColors.green,
              ),
              const SizedBox(height: 24),
              AppText(
                AppStrings.of(context).brand,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              AppText(AppStrings.of(context).tagline),
              const SizedBox(height: 32),
              const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    ),
  );
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  final _phone = TextEditingController(text: AppConfig.phone);
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).login(_phone.text);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is AppException
              ? e.message
              : AppCopy.weCouldNotSaveYourSessionPleaseTry;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final health = ref.watch(healthProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const GuardianBrand(),
                  const SizedBox(height: 42),
                  AppText(
                    AppCopy.yourJourneyNyourGroupNtogether,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    s.tagline,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  const GuardianCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusChip(AppCopy.demoPilgrim),
                        SizedBox(height: 12),
                        AppText(
                          AppCopy.connectToThePilgrimRegisteredByYourAgency,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _phone,
                    enabled: !_busy,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    decoration: const InputDecoration(
                      label: AppText(AppCopy.phoneNumber),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: AppText(
                        _error!,
                        style: const TextStyle(color: AppColors.red),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _login,
                      child: AppText(
                        _busy
                            ? AppCopy.connectingToYourGroup
                            : AppCopy.joinMyHajjGroup,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          health.isLoading
                              ? AppCopy.checkingGuardianConnection
                              : health.value == true
                              ? AppCopy.guardianIsConnected
                              : AppCopy.guardianConnectionUnavailable,
                        ),
                      ),
                      IconButton(
                        tooltip: AppCopy.retryConnection.tr(context),
                        onPressed: () => ref.invalidate(healthProvider),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
