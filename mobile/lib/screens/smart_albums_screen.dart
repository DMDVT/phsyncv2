import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import '../providers/app_providers.dart';
import '../services/smart_album_service.dart';
import 'media_collection_screen.dart';

class SmartAlbumsScreen extends ConsumerWidget {
  const SmartAlbumsScreen({super.key, required this.mode});
  final SmartAlbumMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryProvider);
    final isLocation = mode == SmartAlbumMode.location;
    return Scaffold(
      appBar: AppBar(title: Text(isLocation ? 'Location albums' : 'Date albums')),
      body: gallery.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
        data: (items) {
          final service = SmartAlbumService();
          final groups = isLocation ? service.locationAlbums(items) : service.dateAlbums(items);
          if (groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(isLocation
                    ? 'No photos with GPS metadata were found.'
                    : 'No dated photos were found.'),
              ),
            );
          }
          final entries = groups.entries.toList()
            ..sort((a, b) => isLocation ? a.key.compareTo(b.key) : _latest(b.value).compareTo(_latest(a.value)));
          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                leading: Icon(isLocation ? Icons.location_on : Icons.calendar_month),
                title: Text(entry.key),
                subtitle: Text('${entry.value.length} items'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => MediaCollectionScreen(title: entry.key, items: entry.value),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  DateTime _latest(List<MediaItem> items) => items.map((item) => item.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
}

enum SmartAlbumMode { location, date }
