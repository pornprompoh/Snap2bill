import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/storage/local_receipt_storage.dart';

class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? localImagePath;
  final double size;
  final Widget placeholder;

  const CachedAvatar({
    super.key,
    required this.imageUrl,
    this.localImagePath,
    required this.size,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: localImagePath == null
          ? Future<Uint8List?>.value()
          : readLocalReceipt(localImagePath!),
      builder: (context, snapshot) {
        if (snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _networkImage(),
          );
        }
        return _networkImage();
      },
    );
  }

  Widget _networkImage() {
    final uri = Uri.tryParse(imageUrl ?? '');
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return placeholder;
    }
    return Image.network(
      imageUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
