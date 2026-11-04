import 'dart:typed_data';

import 'package:flutter/material.dart';

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
  late Future<String> _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolvedUrl = _resolveUrl(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant ReceiptImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.localImagePath != widget.localImagePath) {
      _resolvedUrl = _resolveUrl(widget.imageUrl);
    }
  }

  Future<String> _resolveUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Future<String>.error(
        const FormatException('Missing receipt image URL'),
      );
    }
    return SupabaseStorageService().resolveReceiptImageUrl(imageUrl);
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildNetworkImage(context),
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
        return _buildNetworkImage(context);
      },
    );
  }

  Widget _buildNetworkImage(BuildContext context) {
    return FutureBuilder<String>(
      future: _resolvedUrl,
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return widget.errorBuilder?.call(
                context,
                snapshot.error ?? StateError('Receipt image unavailable'),
              ) ??
              const SizedBox.shrink();
        }
        final imageUrl = snapshot.data!;
        return GestureDetector(
          onTap: widget.onTap == null ? null : () => widget.onTap!(imageUrl),
          child: Image.network(
            imageUrl,
            height: widget.height,
            width: widget.width,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) =>
                widget.errorBuilder?.call(context, error) ??
                const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
