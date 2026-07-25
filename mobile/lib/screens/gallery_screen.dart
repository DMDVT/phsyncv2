import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import '../providers/app_providers.dart';
import '../services/media_scanner.dart';
import 'viewer_screen.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  Future<void> _openSettings(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final MediaScanner scanner =
        ref.read(mediaScannerProvider);

    await scanner.openSettings();

    if (context.mounted) {
      ref.invalidate(galleryProvider);
    }
  }

  Future<void> _chooseMorePhotos(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final MediaScanner scanner =
        ref.read(mediaScannerProvider);

    await scanner.chooseMorePhotos();

    if (context.mounted) {
      ref.invalidate(galleryProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PhotoSync'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh gallery',
            onPressed: () {
              ref.invalidate(galleryProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: gallery.when(
        loading: () {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Requesting photo and video access…'),
              ],
            ),
          );
        },
        error: (Object error, StackTrace stackTrace) {
          final bool permissionError =
              error is MediaPermissionException;

          return _PermissionError(
            message: permissionError
                ? error.toString()
                : 'PhotoSync could not load your media.\n\n$error',
            onRetry: () {
              ref.invalidate(galleryProvider);
            },
            onOpenSettings: permissionError
                ? () => _openSettings(context, ref)
                : null,
            onChooseMorePhotos: permissionError
                ? () => _chooseMorePhotos(context, ref)
                : null,
          );
        },
        data: (List<MediaItem> items) {
          if (items.isEmpty) {
            return _PermissionError(
              message:
                  'No accessible photos or videos were found.\n\n'
                  'On Android 14 or newer, you may have allowed only '
                  'selected photos. Choose more photos or grant full '
                  'photo and video access in Android settings.',
              onRetry: () {
                ref.invalidate(galleryProvider);
              },
              onOpenSettings: () {
                _openSettings(context, ref);
              },
              onChooseMorePhotos: () {
                _chooseMorePhotos(context, ref);
              },
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: items.length,
            itemBuilder: (
              BuildContext context,
              int index,
            ) {
              return _Tile(
                item: items[index],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return ViewerScreen(
                          items: items,
                          initialIndex: index,
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.item,
    required this.onTap,
  });

  final MediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ColoredBox(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            child: item.thumbnail == null
                ? const Icon(Icons.image)
                : Image.memory(
                    Uint8List.fromList(item.thumbnail!),
                    fit: BoxFit.cover,
                  ),
          ),
          if (item.isVideo)
            const Positioned(
              right: 6,
              top: 6,
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _PermissionError extends StatelessWidget {
  const _PermissionError({
    required this.message,
    required this.onRetry,
    this.onOpenSettings,
    this.onChooseMorePhotos,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onChooseMorePhotos;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.photo_library_outlined,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Request access again'),
            ),
            if (onChooseMorePhotos != null) ...<Widget>[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onChooseMorePhotos,
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                ),
                label: const Text('Choose accessible photos'),
              ),
            ],
            if (onOpenSettings != null) ...<Widget>[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Open app settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
