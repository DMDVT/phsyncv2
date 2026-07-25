import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../models/media_item.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({required this.items, required this.initialIndex, super.key});
  final List<MediaItem> items;
  final int initialIndex;

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(item.name)),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.items.length,
        onPageChanged: (value) => setState(() => _index = value),
        itemBuilder: (context, index) {
          final media = widget.items[index];
          if (media.thumbnail == null) return const Center(child: Icon(Icons.image, size: 96, color: Colors.white));
          return PhotoView(imageProvider: MemoryImage(Uint8List.fromList(media.thumbnail!)), backgroundDecoration: const BoxDecoration(color: Colors.black));
        },
      ),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: Text(item.createdAt.toLocal().toString(), style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center))),
    );
  }
}
