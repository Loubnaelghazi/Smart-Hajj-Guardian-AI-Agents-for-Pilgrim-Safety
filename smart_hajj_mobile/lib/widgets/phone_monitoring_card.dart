import '../l10n/app_text.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/domain.dart';
import '../providers/session_provider.dart';
import '../providers/dashboard_provider.dart';
import '../services/background_location.dart';
import 'components.dart';

/// Mounted in the trip shell, so changing tabs does not stop the session.
class PhoneMonitoringCard extends ConsumerStatefulWidget {
  const PhoneMonitoringCard({super.key});
  @override
  ConsumerState<PhoneMonitoringCard> createState() =>
      _PhoneMonitoringCardState();
}

class _PhoneMonitoringCardState extends ConsumerState<PhoneMonitoringCard>
    with WidgetsBindingObserver {
  Timer? _timer;
  Timer? _nativeTimer;
  bool _background = false, _nativeRunning = false, _starting = false;
  bool _enabled = false, _busy = false, _foreground = true;
  int _generation = 0;
  String _status =
      'Share GPS while this app is open for automatic safety checks.';
  Json? _received;
  bool _valid(int generation) =>
      mounted && _enabled && _foreground && generation == _generation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (BackgroundLocation.supported) {
      _nativeTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _syncNative(),
      );
      unawaited(_syncNative());
    }
  }

  Future<void> _syncNative() async {
    if (!_foreground || _starting) return;
    try {
      final status = await BackgroundLocation.status();
      if (!mounted || _starting) return;
      final running = status['running'] == true;
      if (running &&
          status['phone'] != ref.read(sessionProvider).value?.phoneNumber) {
        await BackgroundLocation.stop();
        return;
      }
      if (running) {
        _timer?.cancel();
        final receipt = status['receipt'];
        final value = receipt is String ? object(jsonDecode(receipt)) : null;
        setState(() {
          _nativeRunning = true;
          _background = true;
          _enabled = true;
          _received = value;
          _status = '${status['message']}';
          if (value != null) {
            final measured = date(value['measured_at']);
            final age = measured == null
                ? null
                : DateTime.now().difference(measured).inSeconds;
            _status +=
                '\n${value['mocked'] == true ? "Mock GPS" : "Phone GPS"} · ±${number(value['accuracy_m'])?.round()} m · ${age ?? "?"}s ago';
            _status +=
                '\n${age != null && age <= 120 ? value['zone_state'] : "Stale position"} · ${number(value['distance_to_meeting_point_m'])?.round()} m to meeting point';
          }
        });
      } else if (_nativeRunning) {
        _nativeRunning = false;
        _stop('Background sharing stopped. Tap Start to begin a new session.');
      }
    } catch (_) {
      /* A platform channel is unavailable on unsupported test hosts. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _generation++;
      _timer?.cancel();
      if (_enabled && !_nativeRunning) {
        setState(() => _status = 'Paused while the app is in the background.');
      }
    } else if (_nativeRunning) {
      unawaited(_syncNative());
    } else if (_enabled && !_starting) {
      _schedule();
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _sample());
    unawaited(_sample());
  }

  Future<void> _start() async {
    if (_enabled) return;
    _starting = true;
    setState(() {
      _enabled = true;
      _status = 'Requesting location access…';
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted || !_enabled) return;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _stop(
          'Location permission is off. Enable it in phone settings, then start again.',
        );
        return;
      }
      if (_background && BackgroundLocation.supported) {
        final session = ref.read(sessionProvider).value;
        if (session == null) return;
        await BackgroundLocation.start(session.phoneNumber);
        if (!mounted || !_enabled) {
          await BackgroundLocation.stop();
          return;
        }
        _nativeRunning = true;
        setState(() => _status = 'Starting background location sharing…');
      } else {
        _schedule();
      }
    } catch (_) {
      if (mounted) {
        _stop(
          'Could not start sharing. Check location and notification permissions in phone settings.',
        );
      }
    } finally {
      _starting = false;
    }
  }

  void _stop([String? message]) {
    if (_nativeRunning) {
      unawaited(BackgroundLocation.stop());
      _nativeRunning = false;
    }
    _generation++;
    _timer?.cancel();
    setState(() {
      _enabled = false;
      _received = null;
      _status =
          message ?? 'Monitoring stopped. No further GPS updates will be sent.';
    });
  }

  Future<void> _sample() async {
    if (_busy || !_enabled || !_foreground || _nativeRunning || _background) {
      return;
    }
    final generation = _generation;
    _busy = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (_valid(generation)) {
          setState(
            () => _status =
                'Turn on phone location services. Retrying in 30 seconds.',
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!_valid(generation)) return;
      final connections = await Connectivity().checkConnectivity();
      if (!_valid(generation)) return;
      final session = ref.read(sessionProvider).value;
      if (session == null) return;
      final response = object(
        await ref.read(apiProvider).post('/api/mobile/observations', {
          'phone_number': session.phoneNumber,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy_m': position.accuracy,
          'measured_at': position.timestamp.toUtc().toIso8601String(),
          'mocked': position.isMocked,
          'connection': connections.map((c) => c.name).toList(),
        }),
      );
      if (!_valid(generation)) return;
      setState(() {
        _received = response;
        _status =
            '${position.isMocked ? "Mock GPS" : "Phone GPS"} • ±${position.accuracy.round()} m • ${connections.map((c) => c.name).join(", ")}\n'
            'Server received ${DateTime.now().toLocal().toString().substring(11, 19)} • ${response["zone_state"]}\n'
            '${number(response["distance_to_meeting_point_m"])?.round() ?? "—"} m to meeting point'
            '${response["usable_for_distance"] == true ? "" : " • Accuracy too low for risk checks"}';
      });
      await ref.read(dashboardProvider.notifier).check();
    } catch (_) {
      if (_valid(generation)) {
        setState(() {
          _received = null;
          _status = 'GPS or server update unavailable. No new location confirmed. Retrying in 30 seconds.';
        });
      }
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _generation++;
    _timer?.cancel();
    _nativeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GuardianCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              _enabled ? Icons.location_on : Icons.location_off_outlined,
              color: const Color(0xFF087A5B),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: AppText(
                'Phone safety monitoring',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: _enabled ? _stop : _start,
              child: AppText(_enabled ? 'Stop' : 'Start'),
            ),
          ],
        ),
        AppText(_status, style: Theme.of(context).textTheme.bodySmall),
        if (!_enabled && BackgroundLocation.supported)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const AppText(
              'Monitoring settings',
              style: TextStyle(fontSize: 13),
            ),
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const AppText(
                  'Keep sharing in background',
                  style: TextStyle(fontSize: 13),
                ),
                subtitle: const AppText(
                  'Shares GPS with your agency when minimized or locked. Stop here or in the notification.',
                  style: TextStyle(fontSize: 11),
                ),
                value: _background,
                onChanged: (value) => setState(() => _background = value),
              ),
            ],
          ),
        if (_received != null)
          TextButton.icon(
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const AppText('View my position on map'),
            onPressed: () async {
              final p = _received!;
              final uri = Uri.https('www.google.com', '/maps/search/', {
                'api': '1',
                'query': '${p["latitude"]},${p["longitude"]}',
              });
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {
                /* Map is optional. */
              }
            },
          ),
      ],
    ),
  );
}
