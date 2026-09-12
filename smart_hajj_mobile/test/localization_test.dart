import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hajj_mobile/app.dart';
import 'package:smart_hajj_mobile/l10n/arabic.dart';
import 'package:smart_hajj_mobile/providers/locale_provider.dart';
import 'package:smart_hajj_mobile/providers/session_provider.dart';
import 'package:smart_hajj_mobile/core/network/dio_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('every centralized UI message has an Arabic translation', () {
    final source = File('lib/l10n/app_copy.dart').readAsStringSync();
    final regex = RegExp(
      r'''static const \w+\s*=\s*(['"])((?:\\.|(?!\1).)*)\1;''',
      dotAll: true,
    );
    final values = regex
        .allMatches(source)
        .map((m) => m[2]!.replaceAll(r'\n', '\n').replaceAll(r"\'", "'"))
        .toList();
    expect(values.length, greaterThan(100));
    expect(values.where((s) => !arabic.containsKey(s)), isEmpty);
    expect(
      translate('450 m to meeting point', 'ar'),
      '450 متر إلى نقطة التجمّع',
    );
    expect(translate('+212600000000', 'ar'), '+212600000000');
  });
  test('language preference persists across provider containers', () async {
    SharedPreferences.setMockInitialValues({});
    final first = ProviderContainer();
    await first.read(localeProvider.future);
    await first.read(localeProvider.notifier).change('ar');
    first.dispose();
    final restored = ProviderContainer();
    expect((await restored.read(localeProvider.future)).languageCode, 'ar');
    restored.dispose();
  });
  for (final language in ['en', 'ar']) {
    testWidgets(
      '$language full app routes fit a small phone and SOS can be cancelled',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          'guardian.language': language,
          'guardian.session': jsonEncode({
            'pilgrim_id': 'p',
            'group_id': 'g',
            'agency_id': 'a',
            'phone_number': '+1',
          }),
        });
        var posts = 0;
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (r, h) {
              if (r.method == 'POST') posts++;
              final data = switch (r.path) {
                '/api/pilgrims/p' => {
                  'id': 'p',
                  'group_id': 'g',
                  'agency_id': 'a',
                  'phone_number': '+1',
                  'name': 'Ahmed',
                },
                '/api/groups/g' => {
                  'group': {'id': 'g', 'name': 'Group A'},
                  'safe_zone': null,
                },
                '/api/groups/g/safe-zone' => {'safe_zone': null},
                '/api/agencies/a' => {'id': 'a', 'name': 'Agency'},
                '/api/incidents/active' => [],
                '/api/pilgrims' => {'pilgrims': []},
                _ => {'status': 'ok'},
              };
              h.resolve(Response(requestOptions: r, data: data));
            },
          ),
        );
        final container = ProviderContainer(
          overrides: [apiProvider.overrideWithValue(ApiClient(dio: dio))],
        );
        await container.read(localeProvider.future);
        await container.read(sessionProvider.future);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const GuardianApp(),
          ),
        );
        await tester.pumpAndSettle();
        for (final route in [
          '/home',
          '/group',
          '/safety',
          '/profile',
          '/safe-zone',
          '/return',
          '/emergency',
        ]) {
          container.read(routerProvider).go(route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: route);
          expect(
            Directionality.of(tester.element(find.byType(Scaffold).first)),
            language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
        }
        container.read(routerProvider).go('/home');
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(
            language == 'ar' ? 'استغاثة · أحتاج مساعدة' : 'SOS · I need help',
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(language == 'ar' ? 'إلغاء' : 'Cancel'));
        await tester.pumpAndSettle();
        expect(posts, 0);
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      },
    );
  }
}
