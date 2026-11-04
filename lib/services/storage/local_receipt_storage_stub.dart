import 'dart:convert';
import 'dart:typed_data';

Future<String> saveLocalReceipt(Uint8List bytes, String billId) async {
  return 'data:image/jpeg;base64,${base64Encode(bytes)}';
}

Future<Uint8List?> readLocalReceipt(String path) async {
  const prefix = 'data:image/jpeg;base64,';
  if (!path.startsWith(prefix)) return null;
  return base64Decode(path.substring(prefix.length));
}
