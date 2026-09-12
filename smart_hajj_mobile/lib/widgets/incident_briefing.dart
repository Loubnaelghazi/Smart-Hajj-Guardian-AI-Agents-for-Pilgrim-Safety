import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/domain.dart';
import '../providers/session_provider.dart';
import 'components.dart';

class IncidentBriefing extends ConsumerStatefulWidget {
  const IncidentBriefing({super.key, required this.incident});
  final Incident incident;
  @override
  ConsumerState<IncidentBriefing> createState() => _IncidentBriefingState();
}

class _IncidentBriefingState extends ConsumerState<IncidentBriefing> {
  bool _arabic = false, _busy = false;
  Json? _data;
  bool _error = false;
  int _generation = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _arabic = Localizations.localeOf(context).languageCode == 'ar';
  }

  @override
  void didUpdateWidget(covariant IncidentBriefing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.incident.id != widget.incident.id ||
        oldWidget.incident.status != widget.incident.status) {
      _generation++;
      _data = null;
      _busy = false;
    }
  }

  Future<void> _generate() async {
    if (_busy) return;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = false;
    });
    try {
      final value = object(
        await ref
            .read(apiProvider)
            .post(
              '/api/incidents/${Uri.encodeComponent(widget.incident.id)}/briefing',
              {},
            ),
      );
      if (!mounted || generation != _generation) return;
      if (value['incident_id'] != widget.incident.id ||
          value['incident_status'] != widget.incident.status ||
          value['facts'] is! List) {
        throw const FormatException();
      }
      setState(() => _data = value);
    } catch (_) {
      if (mounted && generation == _generation) setState(() => _error = true);
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = _arabic ? 'ar' : 'en';
    return Directionality(
      textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
      child: GuardianCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _arabic ? 'ملخص البلاغ' : 'Incident briefing',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => setState(() => _arabic = !_arabic),
                  child: Text(_arabic ? 'English' : 'العربية'),
                ),
              ],
            ),
            if (_data != null) ...[
              Text(
                _data!['mode'] == 'ai_prioritized'
                    ? (_arabic
                          ? 'ترتيب الأولويات بمساعدة الذكاء الاصطناعي'
                          : 'AI-prioritized evidence')
                    : (_arabic
                          ? 'ملخص البيانات — الذكاء الاصطناعي غير متاح'
                          : 'Evidence summary — AI unavailable'),
              ),
              const SizedBox(height: 12),
              for (final fact in objects(_data!['facts']))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(string(fact[language]) ?? '—'),
                ),
              Text(
                string(object(_data!['notice'])[language]) ?? '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${_arabic ? "وقت الملخص" : "Snapshot"}: ${date(_data!['generated_at'])?.toLocal() ?? "—"}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_error)
              Text(
                _arabic
                    ? 'تعذّر تحميل الملخص. حاول مجدداً.'
                    : 'Briefing unavailable. Please retry.',
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _generate,
              child: Text(
                _busy
                    ? (_arabic ? 'جارٍ التحضير…' : 'Preparing…')
                    : (_arabic ? 'تحديث الملخص' : 'Prepare / refresh briefing'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
