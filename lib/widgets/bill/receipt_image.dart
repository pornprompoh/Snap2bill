import 'package:flutter/material.dart';

import '../../services/storage/supabase_storage_service.dart';

class ReceiptImage extends StatefulWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final ValueChanged<String>? onTap;

  const ReceiptImage({
    super.key,
    required this.imageUrl,
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
    _resolvedUrl = _resolveUrl();
  }

  @override
  void didUpdateWidget(covariant ReceiptImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resolvedUrl = _resolveUrl();
    }
  }

  Future<String> _resolveUrl() =>
      SupabaseStorageService().resolveReceiptImageUrl(widget.imageUrl);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _resolvedUrl,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return widget.errorBuilder?.call(context, snapshot.error!) ??
              const SizedBox.shrink();
        }
        if (!snapshot.hasData) {
          return SizedBox(
            height: widget.height,
            width: widget.width,
            child: const Center(child: CircularProgressIndicator()),
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
            errorBuilder: (context, error, stackTrace) =>
                widget.errorBuilder?.call(context, error) ??
                const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
