import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

class MediaItem {
  const MediaItem({
    required this.asset,
    required this.name,
    required this.createdAt,
    required this.type,
    this.thumbnail,
    this.tags = const <String>[],
    this.isFavorite = false,
    this.latitude,
    this.longitude,
  });

  final AssetEntity asset;
  final String name;
  final DateTime createdAt;
  final AssetType type;
  final Uint8List? thumbnail;
  final List<String> tags;
  final bool isFavorite;
  final double? latitude;
  final double? longitude;

  bool get isVideo => type == AssetType.video;
  bool get hasLocation => latitude != null && longitude != null && (latitude != 0 || longitude != 0);
}
