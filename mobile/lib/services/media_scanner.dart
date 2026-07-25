import 'package:photo_manager/photo_manager.dart';
import '../models/album_info.dart';
import '../models/media_item.dart';

class MediaScanner {
  Future<PermissionState> requestPermission() => PhotoManager.requestPermissionExtend();

  Future<List<AlbumInfo>> albums() async {
    final permission = await requestPermission();
    if (!permission.isAuth) return const <AlbumInfo>[];
    final paths = await PhotoManager.getAssetPathList(type: RequestType.common);
    final result = <AlbumInfo>[];
    for (final path in paths) {
      result.add(AlbumInfo(path: path, count: await path.assetCountAsync));
    }
    return result;
  }

  Future<List<MediaItem>> scan({int limit = 1000, DateTime? from, DateTime? to, int thumbnailSize = 320}) async {
    final permission = await requestPermission();
    if (!permission.isAuth) return const <MediaItem>[];
    final paths = await PhotoManager.getAssetPathList(type: RequestType.common, onlyAll: true);
    if (paths.isEmpty) return const <MediaItem>[];
    final count = await paths.first.assetCountAsync;
    final assets = await paths.first.getAssetListRange(start: 0, end: count < limit ? count : limit);
    final items = <MediaItem>[];
    for (final asset in assets) {
      final created = asset.createDateTime;
      if (from != null && created.isBefore(from)) continue;
      if (to != null && created.isAfter(to)) continue;
      final thumb = await asset.thumbnailDataWithSize(ThumbnailSize.square(thumbnailSize), quality: 75);
      items.add(MediaItem(
        asset: asset,
        name: asset.title ?? 'Untitled',
        createdAt: created,
        type: asset.type,
        thumbnail: thumb,
        tags: _heuristicTags(asset.title ?? ''),
        latitude: asset.latitude,
        longitude: asset.longitude,
      ));
    }
    return items;
  }

  Future<List<MediaItem>> resolveAssetIds(List<String> ids) async {
    final result = <MediaItem>[];
    for (final id in ids) {
      final asset = await AssetEntity.fromId(id);
      if (asset == null) continue;
      final thumb = await asset.thumbnailDataWithSize(const ThumbnailSize.square(320), quality: 75);
      result.add(MediaItem(
        asset: asset,
        name: asset.title ?? 'Untitled',
        createdAt: asset.createDateTime,
        type: asset.type,
        thumbnail: thumb,
        latitude: asset.latitude,
        longitude: asset.longitude,
      ));
    }
    return result;
  }

  List<String> _heuristicTags(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('screenshot')) return const <String>['Screenshot', 'Document'];
    if (lower.contains('img') || lower.contains('photo')) return const <String>['Photo'];
    if (lower.contains('vid')) return const <String>['Video'];
    return const <String>[];
  }
}
