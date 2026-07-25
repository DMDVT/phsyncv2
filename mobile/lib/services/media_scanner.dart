import 'package:photo_manager/photo_manager.dart';

import '../models/album_info.dart';
import '../models/media_item.dart';

class MediaPermissionResult {
  const MediaPermissionResult({
    required this.state,
  });

  final PermissionState state;

  bool get canReadMedia => state.isAuth || state.hasAccess;

  bool get isLimited => state == PermissionState.limited;

  bool get isDenied =>
      state == PermissionState.denied ||
      state == PermissionState.restricted;
}

class MediaPermissionException implements Exception {
  const MediaPermissionException(this.state);

  final PermissionState state;

  @override
  String toString() {
    if (state == PermissionState.restricted) {
      return 'Photo and video access is restricted on this device.';
    }

    if (state == PermissionState.denied) {
      return 'Photo and video permission was denied.';
    }

    return 'Photo and video permission is required.';
  }
}

class MediaScanner {
  static const PermissionRequestOption _permissionOptions =
      PermissionRequestOption(
    androidPermission: AndroidPermission(
      type: RequestType.common,
      mediaLocation: true,
    ),
  );

  Future<MediaPermissionResult> requestPermission() async {
    final PermissionState state =
        await PhotoManager.requestPermissionExtend(
      requestOption: _permissionOptions,
    );

    return MediaPermissionResult(state: state);
  }

  Future<MediaPermissionResult> permissionState() async {
    final PermissionState state =
        await PhotoManager.getPermissionState(
      requestOption: _permissionOptions,
    );

    return MediaPermissionResult(state: state);
  }

  Future<void> openSettings() async {
    await PhotoManager.openSetting();
  }

  Future<void> chooseMorePhotos() async {
    await PhotoManager.presentLimited(
      type: RequestType.common,
    );
  }

  Future<List<AlbumInfo>> albums() async {
    final MediaPermissionResult permission =
        await requestPermission();

    if (!permission.canReadMedia) {
      throw MediaPermissionException(permission.state);
    }

    final List<AssetPathEntity> paths =
        await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );

    final List<AlbumInfo> result = <AlbumInfo>[];

    for (final AssetPathEntity path in paths) {
      result.add(
        AlbumInfo(
          path: path,
          count: await path.assetCountAsync,
        ),
      );
    }

    return result;
  }

  Future<List<MediaItem>> scan({
    int limit = 1000,
    DateTime? from,
    DateTime? to,
    int thumbnailSize = 320,
  }) async {
    final MediaPermissionResult permission =
        await requestPermission();

    if (!permission.canReadMedia) {
      throw MediaPermissionException(permission.state);
    }

    final List<AssetPathEntity> paths =
        await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
    );

    if (paths.isEmpty) {
      return const <MediaItem>[];
    }

    final AssetPathEntity allMedia = paths.first;
    final int totalCount = await allMedia.assetCountAsync;
    final int end = totalCount < limit ? totalCount : limit;

    if (end == 0) {
      return const <MediaItem>[];
    }

    final List<AssetEntity> assets =
        await allMedia.getAssetListRange(
      start: 0,
      end: end,
    );

    final List<MediaItem> items = <MediaItem>[];

    for (final AssetEntity asset in assets) {
      final DateTime created = asset.createDateTime;

      if (from != null && created.isBefore(from)) {
        continue;
      }

      if (to != null && created.isAfter(to)) {
        continue;
      }

      final thumbnail = await asset.thumbnailDataWithSize(
        ThumbnailSize.square(thumbnailSize),
        quality: 75,
      );

      items.add(
        MediaItem(
          asset: asset,
          name: asset.title ?? 'Untitled',
          createdAt: created,
          type: asset.type,
          thumbnail: thumbnail,
          tags: _heuristicTags(asset.title ?? ''),
          latitude: asset.latitude,
          longitude: asset.longitude,
        ),
      );
    }

    return items;
  }

  Future<List<MediaItem>> resolveAssetIds(
    List<String> ids,
  ) async {
    final MediaPermissionResult permission =
        await requestPermission();

    if (!permission.canReadMedia) {
      throw MediaPermissionException(permission.state);
    }

    final List<MediaItem> result = <MediaItem>[];

    for (final String id in ids) {
      final AssetEntity? asset = await AssetEntity.fromId(id);

      if (asset == null) {
        continue;
      }

      final thumbnail = await asset.thumbnailDataWithSize(
        const ThumbnailSize.square(320),
        quality: 75,
      );

      result.add(
        MediaItem(
          asset: asset,
          name: asset.title ?? 'Untitled',
          createdAt: asset.createDateTime,
          type: asset.type,
          thumbnail: thumbnail,
          latitude: asset.latitude,
          longitude: asset.longitude,
        ),
      );
    }

    return result;
  }

  List<String> _heuristicTags(String name) {
    final String lower = name.toLowerCase();

    if (lower.contains('screenshot')) {
      return const <String>[
        'Screenshot',
        'Document',
      ];
    }

    if (lower.contains('img') || lower.contains('photo')) {
      return const <String>['Photo'];
    }

    if (lower.contains('vid')) {
      return const <String>['Video'];
    }

    return const <String>[];
  }
}
