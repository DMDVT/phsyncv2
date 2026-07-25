import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/media_item.dart';
import 'viewer_screen.dart';

class MediaCollectionScreen extends StatelessWidget {
  const MediaCollectionScreen({super.key, required this.title, required this.items});
  final String title;
  final List<MediaItem> items;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: items.isEmpty
            ? const Center(child: Text('No photos in this album.'))
            : GridView.builder(
                padding: const EdgeInsets.all(2),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => ViewerScreen(items: items, initialIndex: index),
                      ),
                    ),
                    child: item.thumbnail == null
                        ? const ColoredBox(color: Colors.black12, child: Icon(Icons.image))
                        : Image.memory(Uint8List.fromList(item.thumbnail!), fit: BoxFit.cover),
                  );
                },
              ),
      );
}
