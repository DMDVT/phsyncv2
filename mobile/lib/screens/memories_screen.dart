import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/media_item.dart';
import '../providers/app_providers.dart';
import '../services/smart_album_service.dart';
import 'media_collection_screen.dart';

class MemoriesScreen extends ConsumerWidget {
  const MemoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Memories'),
          bottom: const TabBar(
            tabs: <Tab>[
              Tab(text: 'On this day'),
              Tab(text: 'Years'),
            ],
          ),
        ),
        body: gallery.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text(error.toString())),
          data: (items) {
            final service = SmartAlbumService();
            final onThisDay = service.onThisDay(items, DateTime.now());
            final yearly = service.yearlyMemories(items).entries.toList()
              ..sort((a, b) => b.key.compareTo(a.key));
            return TabBarView(
              children: <Widget>[
                _OnThisDay(items: onThisDay),
                _YearlyMemories(entries: yearly),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OnThisDay extends StatelessWidget {
  const _OnThisDay({required this.items});
  final List<MediaItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No “On this day” memories yet.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            item.thumbnail == null
                ? const ColoredBox(color: Colors.black12, child: Icon(Icons.image))
                : Image.memory(Uint8List.fromList(item.thumbnail!), fit: BoxFit.cover),
            Positioned(
              left: 4,
              bottom: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Text('${DateTime.now().year - item.createdAt.year}y ago', style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _YearlyMemories extends StatelessWidget {
  const _YearlyMemories({required this.entries});
  final List<MapEntry<int, List<MediaItem>>> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const Center(child: Text('No yearly memories yet.'));
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final cover = entry.value.firstOrNull;
        return ListTile(
          leading: SizedBox(
            width: 56,
            height: 56,
            child: cover?.thumbnail == null
                ? const ColoredBox(color: Colors.black12, child: Icon(Icons.auto_awesome))
                : Image.memory(Uint8List.fromList(cover!.thumbnail!), fit: BoxFit.cover),
          ),
          title: Text('${entry.key} memories'),
          subtitle: Text('${entry.value.length} items · ${DateFormat.y().format(DateTime(entry.key))}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MediaCollectionScreen(title: '${entry.key} memories', items: entry.value),
            ),
          ),
        );
      },
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
