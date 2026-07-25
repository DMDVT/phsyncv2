import '../models/media_item.dart';

class StorageSummary {
  const StorageSummary({required this.photos, required this.videos, required this.totalBytes});
  final int photos;
  final int videos;
  final int totalBytes;
}

class StorageService {
  Future<StorageSummary> summarize(List<MediaItem> items) async {
    var photos = 0;
    var videos = 0;
    var bytes = 0;
    for (final item in items) {
      if (item.isVideo) {
        videos++;
      } else {
        photos++;
      }
      final file = await item.asset.file;
      if (file != null && await file.exists()) bytes += await file.length();
    }
    return StorageSummary(photos: photos, videos: videos, totalBytes: bytes);
  }
}
