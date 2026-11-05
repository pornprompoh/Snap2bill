import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/services/join/pending_join_store.dart';

void main() {
  const store = PendingJoinStore();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('reads null when no pending room is stored', () async {
    expect(await store.read(), isNull);
  });

  test('saves and reads the pending room id', () async {
    await store.save('ROOM42');

    expect(await store.read(), 'ROOM42');
  });

  test('returns an empty stored room id unchanged', () async {
    await store.save('  ');

    expect(await store.read(), isNull);
  });

  test('clears a pending room id', () async {
    await store.save('ROOM42');
    await store.clear();

    expect(await store.read(), isNull);
  });
}
