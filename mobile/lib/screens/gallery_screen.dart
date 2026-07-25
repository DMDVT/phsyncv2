import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import '../providers/app_providers.dart';
import 'viewer_screen.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('PhotoSync'),
        actions: <Widget>[IconButton(onPressed: () => ref.invalidate(galleryProvider), icon: const Icon(Icons.refresh))],
      ),
      body: gallery.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _PermissionError(message: error.toString(), onRetry: () => ref.invalidate(galleryProvider)),
        data: (items) {
          if (items.isEmpty) return _PermissionError(message: 'No accessible media was found. Grant photo and video access in Android settings.', onRetry: () => ref.invalidate(galleryProvider));
          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
            itemCount: items.length,
            itemBuilder: (context, index) => _Tile(item: items[index], onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => ViewerScreen(items: items, initialIndex: index)))),
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.onTap});
  final MediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: item.thumbnail == null ? const Icon(Icons.image) : Image.memory(Uint8List.fromList(item.thumbnail!), fit: BoxFit.cover),
            ),
            if (item.isVideo) const Positioned(right: 6, top: 6, child: Icon(Icons.play_circle_fill, color: Colors.white)),
          ],
        ),
      );
}

class _PermissionError extends StatelessWidget {
  const _PermissionError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.photo_library_outlined, size: 64),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
}
