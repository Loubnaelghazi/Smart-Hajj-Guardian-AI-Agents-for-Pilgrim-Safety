import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_hajj_mobile/core/network/dio_client.dart';
import 'package:smart_hajj_mobile/models/domain.dart';
import 'package:smart_hajj_mobile/providers/session_provider.dart';
import 'package:smart_hajj_mobile/widgets/incident_briefing.dart';

void main() {
  testWidgets(
    'same evidence renders in English and Arabic with RTL and honest fallback',
    (tester) async {
      final dio = Dio();
      var requests = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) {
            requests++;
            h.resolve(
              Response(
                requestOptions: r,
                data: {
                  'incident_id': 'test',
                  'incident_status': 'OPEN',
                  'mode': 'evidence_summary',
                  'generated_at': '2026-09-10T10:00:00Z',
                  'facts': [
                    {
                      'id': 'status',
                      'en': 'No acknowledgment recorded.',
                      'ar': 'لم يُسجّل إقرار الاستلام.',
                    },
                  ],
                  'notice': {
                    'en': 'Evidence snapshot.',
                    'ar': 'لقطة من البيانات.',
                  },
                },
              ),
            );
          },
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiProvider.overrideWithValue(ApiClient(dio: dio))],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: IncidentBriefing(
                  incident: Incident.fromJson({
                    'id': 'test',
                    'status': 'OPEN',
                    'risk_level': 'CRITICAL',
                  }),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Prepare / refresh briefing'));
      await tester.pumpAndSettle();
      expect(find.text('No acknowledgment recorded.'), findsOneWidget);
      expect(find.text('Evidence summary — AI unavailable'), findsOneWidget);
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      final arabic = find.text('لم يُسجّل إقرار الاستلام.');
      expect(arabic, findsOneWidget);
      expect(Directionality.of(tester.element(arabic)), TextDirection.rtl);
      expect(requests, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
