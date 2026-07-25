import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../models/media_item.dart';

class DuplicateGroup {
  const DuplicateGroup(this.items, this.averageDistance);
  final List<MediaItem> items;
  final double averageDistance;
}

class DuplicateService {
  Future<List<DuplicateGroup>> findDuplicates(List<MediaItem> items) async {
    final imageItems = items.where((item) => !item.isVideo && item.thumbnail != null).toList();
    final hashes = <MediaItem, int>{};
    for (final item in imageItems) {
      final decoded = img.decodeImage(item.thumbnail!);
      if (decoded != null) hashes[item] = _differenceHash(decoded);
    }

    final used = <MediaItem>{};
    final groups = <DuplicateGroup>[];
    for (final item in imageItems) {
      if (used.contains(item) || !hashes.containsKey(item)) continue;
      final matches = <MediaItem>[item];
      var distanceTotal = 0;
      for (final other in imageItems) {
        if (identical(item, other) || used.contains(other) || !hashes.containsKey(other)) continue;
        final distance = _hammingDistance(hashes[item]!, hashes[other]!);
        if (distance <= 5) {
          matches.add(other);
          distanceTotal += distance;
        }
      }
      if (matches.length > 1) {
        used.addAll(matches);
        groups.add(DuplicateGroup(matches, distanceTotal / math.max(1, matches.length - 1)));
      }
    }
    groups.sort((a, b) => b.items.length.compareTo(a.items.length));
    return groups;
  }

  int _differenceHash(img.Image source) {
    final gray = img.grayscale(img.copyResize(source, width: 9, height: 8));
    var hash = 0;
    var bit = 0;
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        final left = gray.getPixel(x, y).r;
        final right = gray.getPixel(x + 1, y).r;
        if (left > right) hash |= 1 << bit;
        bit++;
      }
    }
    return hash;
  }

  int _hammingDistance(int a, int b) {
    var value = a ^ b;
    var count = 0;
    while (value != 0) {
      count++;
      value &= value - 1;
    }
    return count;
  }
}
