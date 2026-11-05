import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/services/storage/local_receipt_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  late Directory documentsDirectory;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'snap2bill-receipts-',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return documentsDirectory.path;
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, null);
    if (await documentsDirectory.exists()) {
      await documentsDirectory.delete(recursive: true);
    }
  });

  test('writes and reads a receipt file under the receipts directory', () async {
    final bytes = Uint8List.fromList([0, 1, 2, 255]);

    final path = await saveLocalReceipt(bytes, 'bill-1');

    expect(
      path,
      endsWith(
        '${Platform.pathSeparator}receipts${Platform.pathSeparator}bill-1.jpg',
      ),
    );
    expect(await readLocalReceipt(path), bytes);
  });

  test('returns null when the requested receipt file does not exist', () async {
    expect(
      await readLocalReceipt(
        '${documentsDirectory.path}${Platform.pathSeparator}missing.jpg',
      ),
      isNull,
    );
  });

  test('caches a data URI image and rejects malformed image data', () async {
    final path = await cacheRemoteImage(
      'data:image/png;base64,AQID',
      'remote-image',
    );

    expect(await readLocalReceipt(path), [1, 2, 3]);
    await expectLater(
      cacheRemoteImage('data:image/png', 'invalid'),
      throwsFormatException,
    );
    await expectLater(
      cacheRemoteImage('http://[', 'invalid'),
      throwsFormatException,
    );
  });
}
