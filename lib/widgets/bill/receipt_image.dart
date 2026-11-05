import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/offline/offline_service.dart';
import '../../services/storage/local_receipt_storage.dart';
import '../../services/storage/supabase_storage_service.dart';

class ReceiptImage extends StatefulWidget {
  final String? imageUrl;
  final String? localImagePath;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final ValueChanged<String>? onTap;

  const ReceiptImage({
    super.key,
    this.imageUrl,
    this.localImagePath,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.onTap,
  });

  @override
  State<ReceiptImage> createState() => _ReceiptImageState();
}

class _ReceiptImageState extends State<ReceiptImage> {
  Future<String?>? _resolvedUrl;

  @override
  void didUpdateWidget(covariant ReceiptImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.localImagePath != widget.localImagePath) {
      _resolvedUrl = null;
    }
  }

  Future<String?> _resolveUrl(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }
    try {
      return await SupabaseStorageService().resolveReceiptImageUrl(imageUrl);
    } catch (error, stackTrace) {
      if (OfflineService.isLikelyNetworkError(error)) {
        if (mounted) {
          context.read<OfflineService>().reportNetworkFailure(error);
        }
        debugPrint('Receipt URL unavailable while offline: $error');
        return null;
      }
      debugPrint('Failed to resolve receipt image URL: $error\n$stackTrace');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<OfflineService>().isOffline;
    return FutureBuilder<Uint8List?>(
      future: widget.localImagePath == null
          ? Future<Uint8List?>.value()
          : readLocalReceipt(widget.localImagePath!),
      builder: (context, localSnapshot) {
        final localBytes = localSnapshot.data;
        if (localBytes != null) {
          final localPath = widget.localImagePath!;
          return GestureDetector(
            onTap: widget.onTap == null ? null : () => widget.onTap!(localPath),
            child: Image.memory(
              localBytes,
              height: widget.height,
              width: widget.width,
              fit: widget.fit,
              errorBuilder: (context, error, stackTrace) =>
                  _buildNetworkImage(context, isOffline),
            ),
          );
        }
        if (localSnapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: widget.height,
            width: widget.width,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        return _buildNetworkImage(context, isOffline);
      },
    );
  }

  Widget _buildNetworkImage(BuildContext context, bool isOffline) {
    if (isOffline) return _buildUnavailable(context);
    final resolvedUrl = _resolvedUrl ??= _resolveUrl(widget.imageUrl);
    return FutureBuilder<String?>(
      future: resolvedUrl,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: widget.height,
            width: widget.width,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _buildUnavailable(
            context,
            snapshot.error ?? StateError('Receipt image unavailable'),
          );
        }
        final imageUrl = snapshot.data!;
        return GestureDetector(
          onTap: widget.onTap == null ? null : () => widget.onTap!(imageUrl),
          child: Image.network(
            imageUrl,
            height: widget.height,
            width: widget.width,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              context.read<OfflineService>().reportNetworkFailure(error);
              return widget.errorBuilder?.call(context, error) ??
                  const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildUnavailable(BuildContext context, [Object? error]) {
    return widget.errorBuilder?.call(
          context,
          error ?? StateError('Receipt image unavailable offline'),
        ) ??
        const SizedBox.shrink();
  }
}
