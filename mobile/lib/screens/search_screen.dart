import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final gallery = ref.watch(galleryProvider);
    return Scaffold(
      appBar: AppBar(title: TextField(decoration: const InputDecoration(hintText: 'Search filenames and local tags', border: InputBorder.none), onChanged: (value) => setState(() => query = value.trim().toLowerCase()))),
      body: gallery.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
        data: (items) {
          final results = items.where((item) => item.name.toLowerCase().contains(query) || item.tags.any((tag) => tag.toLowerCase().contains(query))).toList();
          return ListView.builder(itemCount: results.length, itemBuilder: (context, index) => ListTile(leading: const Icon(Icons.image), title: Text(results[index].name), subtitle: Text(results[index].tags.join(', '))));
        },
      ),
    );
  }
}
