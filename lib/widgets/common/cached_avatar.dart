import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/offline/offline_service.dart';
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
    final isOffline = context.watch<OfflineService>().isOffline;
    return FutureBuilder<Uint8List?>(
      future: localImagePath == null
          ? Future<Uint8List?>.value()
          : readLocalReceipt(localImagePath!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder;
        }
        if (snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                isOffline ? placeholder : _networkImage(context),
          );
        }
        if (isOffline || snapshot.hasError) return placeholder;
        return _networkImage(context);
      },
    );
  }

  Widget _networkImage(BuildContext context) {
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
      errorBuilder: (context, error, stackTrace) {
        context.read<OfflineService>().reportNetworkFailure(error);
        return placeholder;
      },
    );
  }
}
