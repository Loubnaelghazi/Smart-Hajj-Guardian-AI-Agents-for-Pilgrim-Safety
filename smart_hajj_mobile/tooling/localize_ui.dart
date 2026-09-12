import 'dart:io';

void main() {
  for (final path in [
    'lib/screens/onboarding_screen.dart', 'lib/screens/trip_screen.dart',
    'lib/widgets/components.dart', 'lib/widgets/guardian_brand.dart',
    'lib/widgets/sos_button.dart', 'lib/widgets/phone_monitoring_card.dart',
  ]) {
    final file = File(path);
    var source = file.readAsStringSync();
    source = source.replaceAll(RegExp(r'\bText\('), 'AppText(');
    if (!source.contains("import '../l10n/app_text.dart';")) source = "import '../l10n/app_text.dart';\n$source";
    file.writeAsStringSync(source);
  }
  final file = File('lib/l10n/app_strings.dart');
  var source = file.readAsStringSync();
  source = source.replaceFirst("import '../models/domain.dart';", "import '../models/domain.dart';\nimport 'arabic.dart';");
  source = source.replaceFirst('const AppStrings();', "const AppStrings([this.language = 'en']);\n  final String language;\n  String _t(String message) => translate(message, language);");
  source = source.replaceAllMapped(RegExp(r"(String get \w+\s*=>\s*)('(?:[^'\\]|\\.)*');"), (m) => '${m[1]}_t(${m[2]});');
  source = source.replaceFirst("locale.languageCode == 'en'", "['en', 'ar'].contains(locale.languageCode)");
  source = source.replaceFirst('SynchronousFuture(const AppStrings())', 'SynchronousFuture(AppStrings(locale.languageCode))');
  file.writeAsStringSync(source);
}
