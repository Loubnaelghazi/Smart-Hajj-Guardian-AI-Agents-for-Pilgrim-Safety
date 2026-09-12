import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../core/storage/local_storage.dart';
import '../models/domain.dart';
import '../repositories/repositories.dart';
import '../services/background_location.dart';

final apiProvider = Provider<ApiClient>((ref) {
  final api = ApiClient();
  ref.onDispose(() => api.dio.close(force: true));
  return api;
});
final storageProvider = Provider((ref) => LocalStorage());
final healthProvider = FutureProvider<bool>((ref) async {
  try {
    return object(await ref.watch(apiProvider).get('/health'))['status'] ==
        'ok';
  } catch (_) {
    return false;
  }
});
final sessionProvider =
    AsyncNotifierProvider<SessionController, PilgrimSession?>(
      SessionController.new,
    );

class SessionController extends AsyncNotifier<PilgrimSession?> {
  bool _busy = false;
  @override
  Future<PilgrimSession?> build() => ref.watch(storageProvider).restore();
  Future<void> login(String phone) async {
    if (_busy) return;
    _busy = true;
    try {
      final pilgrim = await PilgrimRepository(ref.read(apiProvider))
          .findByPhone(phone);
      final session = PilgrimSession(
        pilgrimId: pilgrim.id,
        groupId: pilgrim.groupId,
        agencyId: pilgrim.agencyId,
        phoneNumber: pilgrim.phone!,
      );
      await ref.read(storageProvider).save(session);
      if (ref.mounted) state = AsyncData(session);
    } finally {
      _busy = false;
    }
  }

  Future<void> logout() async {
    await BackgroundLocation.stop();
    await ref.read(storageProvider).clear();
    if (ref.mounted) state = const AsyncData(null);
  }
}
