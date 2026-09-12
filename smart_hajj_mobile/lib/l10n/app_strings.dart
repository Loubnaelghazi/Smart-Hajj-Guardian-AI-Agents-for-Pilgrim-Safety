import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/domain.dart';
import 'arabic.dart';

/// English catalog with a Flutter localization delegate. Add translated catalogs
/// and supported locales here; layouts use directional padding and alignment.
class AppStrings {
  const AppStrings([this.language = 'en']);
  final String language;
  String _t(String message) => translate(message, language);
  static const delegate = _StringsDelegate();
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ?? const AppStrings();
  String get brand => _t('Smart Hajj Guardian');
  String get tagline => _t('Your group safety companion.');
  String get home => _t('Home');
  String get group => _t('Group');
  String get safety => _t('Safety');
  String get profile => _t('Profile');
  String get unknown => _t('Not available');
  String get noZone =>
      _t('Your agency has not configured a group safe zone yet.');
  String get noGuide => _t('A guide has not been assigned yet.');
  String get check => _t('Check safety now');
  String get contact => _t('Call guide');
  String get returnToGroup => _t('Return to your group');
  String get emergency => _t('Emergency status');
  String get noAnalysis => _t('Run your first safety check');
  String get limited => _t('Safety data is limited. Stay close to your group.');
  String get stale =>
      _t('Some safety information is outdated. Refresh before relying on it.');
  String risk(RiskLevel level) => _t(switch (level) {
    RiskLevel.low => 'LOW RISK',
    RiskLevel.medium => 'MEDIUM RISK',
    RiskLevel.high => 'HIGH RISK',
    RiskLevel.critical => 'CRITICAL',
    RiskLevel.unknown => 'NOT CHECKED',
  });
  String action(String? action) => _t(switch (action) {
    'CONTINUE_MONITORING' => 'Continue with your group.',
    'RETURN_TO_GROUP' => 'Move back toward your group.',
    'WAIT_FOR_GUIDE' => 'Stay where you are and wait for guide support.',
    'AVOID_CONGESTED_ZONE' =>
      'Avoid the congested area. Contact your guide for a safer route.',
    'MOVE_TO_SAFE_CHECKPOINT' => 'Move toward the designated safe checkpoint.',
    _ => 'Stay close to your group and contact your guide if you need help.',
  });
}

class _StringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _StringsDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(locale.languageCode));
  @override
  bool shouldReload(_StringsDelegate old) => false;
}
