import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hajj_mobile/app.dart';
import 'package:smart_hajj_mobile/core/config/app_config.dart';
import 'package:smart_hajj_mobile/core/network/dio_client.dart';
import 'package:smart_hajj_mobile/models/domain.dart';
import 'package:smart_hajj_mobile/providers/session_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('another registered phone signs into its own profile', (
    tester,
  ) async {
    final api = ApiClient();
    final records = objects(
      await api.get('/api/groups/${AppConfig.groupId}/pilgrims'),
    );
    api.dio.close();
    final other = records.firstWhere((p) => p['id'] != AppConfig.pilgrimId);
    await (await SharedPreferences.getInstance()).remove('guardian.session');
    await tester.pumpWidget(const ProviderScope(child: GuardianApp()));
    Future<void> until(bool Function() done) async {
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (done()) return;
      }
      expect(done(), isTrue);
    }

    await until(() => find.text('Join my Hajj group').evaluate().isNotEmpty);
    await tester.enterText(
      find.byType(TextField),
      other['phone_number'] as String,
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await until(() => find.textContaining('Hello,').evaluate().isNotEmpty);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GuardianApp)),
    );
    final session = container.read(sessionProvider).value!;
    expect(session.pilgrimId, other['id']);
    expect(session.phoneNumber, other['phone_number']);
    expect(session.groupId, other['group_id']);
    expect(session.agencyId, other['agency_id']);
    expect(
      (await container.read(storageProvider).restore())?.pilgrimId,
      other['id'],
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
