import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/duplicate_service.dart';
import 'media_collection_screen.dart';

class DuplicatesScreen extends ConsumerStatefulWidget {
  const DuplicatesScreen({super.key});

  @override
  ConsumerState<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends ConsumerState<DuplicatesScreen> {
  Future<List<DuplicateGroup>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<DuplicateGroup>> _load() async {
    final items = await ref.read(galleryProvider.future);
    return DuplicateService().findDuplicates(items);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Duplicate photos'),
          actions: <Widget>[
            IconButton(
              onPressed: () => setState(() => _future = _load()),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FutureBuilder<List<DuplicateGroup>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return Center(child: Text('Duplicate scan failed: ${snapshot.error}'));
            final groups = snapshot.data ?? const <DuplicateGroup>[];
            if (groups.isEmpty) return const Center(child: Text('No duplicate or near-duplicate groups found.'));
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final group = groups[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: SizedBox(
                      width: 64,
                      height: 64,
                      child: group.items.first.thumbnail == null
                          ? const Icon(Icons.copy_all)
                          : Image.memory(Uint8List.fromList(group.items.first.thumbnail!), fit: BoxFit.cover),
                    ),
                    title: Text('${group.items.length} similar photos'),
                    subtitle: Text('Visual difference score ${group.averageDistance.toStringAsFixed(1)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => MediaCollectionScreen(
                          title: 'Duplicate group ${index + 1}',
                          items: group.items,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}
