import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/storage_service.dart';

class StorageScreen extends ConsumerWidget {
  const StorageScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Storage')),
      body: gallery.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
        data: (items) => FutureBuilder<StorageSummary>(
          future: StorageService().summarize(items),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!;
            return ListView(padding: const EdgeInsets.all(16), children: <Widget>[
              Text('${(data.totalBytes / 1073741824).toStringAsFixed(2)} GB scanned', style: Theme.of(context).textTheme.headlineMedium),
              ListTile(title: const Text('Photos'), trailing: Text('${data.photos}')),
              ListTile(title: const Text('Videos'), trailing: Text('${data.videos}')),
              const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Compression and duplicate cleanup are intentionally review-first. No original is deleted automatically.'))),
            ]);
          },
        ),
      ),
    );
  }
}
