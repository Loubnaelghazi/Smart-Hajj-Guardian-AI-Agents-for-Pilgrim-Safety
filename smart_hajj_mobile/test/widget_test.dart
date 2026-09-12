import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_hajj_mobile/core/theme/app_theme.dart';
import 'package:smart_hajj_mobile/models/domain.dart';
import 'package:smart_hajj_mobile/widgets/components.dart';
import 'package:smart_hajj_mobile/widgets/sos_button.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: guardianTheme(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
  testWidgets('home does not claim group safety without a verified zone', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SafetyStatusCard(
          result: GuardianResult.fromJson({
            'risk': {'level': 'LOW'},
          }),
          onCheck: () {},
        ),
      ),
    );
    expect(find.text('LOW RISK'), findsOneWidget);
    expect(find.text('Stay connected to your group'), findsOneWidget);
    expect(find.text('Not available'), findsNWidgets(2));
  });
  testWidgets('critical state has explicit instruction, not just red styling', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SafetyStatusCard(
          incident: Incident.fromJson({
            'risk_level': 'CRITICAL',
            'navigation_action': 'WAIT_FOR_GUIDE',
          }),
          onCheck: () {},
        ),
      ),
    );
    expect(find.text('Critical safety alert'), findsOneWidget);
    expect(find.textContaining('Stay where you are'), findsOneWidget);
  });
  testWidgets('SOS requires confirmation, cancellation sends nothing', (
    tester,
  ) async {
    var sent = 0;
    await tester.pumpWidget(host(SOSButton(onConfirmed: () => sent++)));
    await tester.tap(find.text('SOS · I need help'));
    await tester.pumpAndSettle();
    expect(sent, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(sent, 0);
    await tester.tap(find.text('SOS · I need help'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send SOS now'));
    await tester.pumpAndSettle();
    expect(sent, 1);
  });
  testWidgets('small phone with enlarged text has no overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: guardianTheme(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SafetyStatusCard(onCheck: () {}),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
