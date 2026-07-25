import '../models/media_item.dart';

class AiService {
  const AiService();

  Future<List<String>> classify(MediaItem item) async {
    final tags = <String>{...item.tags};
    if (item.isVideo) tags.add('Video');
    if (item.name.toLowerCase().contains('screenshot')) tags.addAll(const <String>['Screenshot', 'OCR candidate']);
    return tags.toList(growable: false);
  }

  Future<String> extractText(MediaItem item) async => '';
  Future<List<double>> embedding(MediaItem item) async => const <double>[];
}
