import 'package:intl/intl.dart';
import '../models/media_item.dart';

class SmartAlbumService {
  Map<String, List<MediaItem>> dateAlbums(List<MediaItem> items) {
    final result = <String, List<MediaItem>>{};
    for (final item in items) {
      final key = DateFormat('MMMM yyyy').format(item.createdAt);
      result.putIfAbsent(key, () => <MediaItem>[]).add(item);
    }
    return result;
  }

  Map<String, List<MediaItem>> locationAlbums(List<MediaItem> items) {
    final result = <String, List<MediaItem>>{};
    for (final item in items.where((item) => item.hasLocation)) {
      final lat = item.latitude!.toStringAsFixed(2);
      final lon = item.longitude!.toStringAsFixed(2);
      final key = 'Near $lat, $lon';
      result.putIfAbsent(key, () => <MediaItem>[]).add(item);
    }
    return result;
  }

  List<MediaItem> onThisDay(List<MediaItem> items, DateTime now) => items
      .where((item) => item.createdAt.month == now.month && item.createdAt.day == now.day && item.createdAt.year < now.year)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Map<int, List<MediaItem>> yearlyMemories(List<MediaItem> items) {
    final result = <int, List<MediaItem>>{};
    for (final item in items) {
      result.putIfAbsent(item.createdAt.year, () => <MediaItem>[]).add(item);
    }
    return result;
  }
}
