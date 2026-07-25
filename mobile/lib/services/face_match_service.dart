import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/media_item.dart';

class FaceScanProgress {
  const FaceScanProgress({required this.processed, required this.total, required this.matches});
  final int processed;
  final int total;
  final int matches;
}

class FaceMatchService {
  FaceMatchService()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.accurate,
            enableLandmarks: true,
            enableContours: false,
            enableClassification: false,
            minFaceSize: 0.12,
          ),
        );

  final FaceDetector _detector;

  Future<List<MediaItem>> findMatches({
    required String referencePath,
    required List<MediaItem> candidates,
    required void Function(FaceScanProgress progress) onProgress,
    double threshold = 0.82,
  }) async {
    final referenceBytes = await FlutterImageCompress.compressWithFile(
      referencePath,
      minWidth: 800,
      minHeight: 800,
      quality: 92,
      format: CompressFormat.jpeg,
    );
    if (referenceBytes == null) throw StateError('The reference image could not be opened.');
    final references = await _embeddingsForBytes(referenceBytes);
    if (references.isEmpty) throw StateError('No clear face was detected in the reference image.');
    final reference = references.first;

    final imageCandidates = candidates.where((item) => !item.isVideo && item.thumbnail != null).toList();
    final matches = <MediaItem>[];
    for (var index = 0; index < imageCandidates.length; index++) {
      final item = imageCandidates[index];
      final embeddings = await _embeddingsForBytes(item.thumbnail!);
      if (embeddings.any((embedding) => _cosine(reference, embedding) >= threshold)) {
        matches.add(item);
      }
      onProgress(FaceScanProgress(processed: index + 1, total: imageCandidates.length, matches: matches.length));
    }
    return matches;
  }

  Future<List<List<double>>> _embeddingsForBytes(Uint8List bytes) async {
    final image = img.decodeImage(bytes);
    if (image == null) return const <List<double>>[];
    final temp = await getTemporaryDirectory();
    final file = File('${temp.path}/photosync_face_${DateTime.now().microsecondsSinceEpoch}.jpg');
    await file.writeAsBytes(Uint8List.fromList(img.encodeJpg(image, quality: 92)), flush: true);
    try {
      final faces = await _detector.processImage(InputImage.fromFilePath(file.path));
      faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height).compareTo(a.boundingBox.width * a.boundingBox.height));
      final result = <List<double>>[];
      for (final face in faces) {
        final box = face.boundingBox;
        final x = box.left.floor().clamp(0, image.width - 1).toInt();
        final y = box.top.floor().clamp(0, image.height - 1).toInt();
        final width = box.width.ceil().clamp(1, image.width - x).toInt();
        final height = box.height.ceil().clamp(1, image.height - y).toInt();
        final crop = img.copyCrop(image, x: x, y: y, width: width, height: height);
        result.add(_visualEmbedding(crop));
      }
      return result;
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  List<double> _visualEmbedding(img.Image face) {
    final normalized = img.copyResize(img.grayscale(face), width: 24, height: 24);
    final values = <double>[];
    var mean = 0.0;
    for (var y = 0; y < normalized.height; y++) {
      for (var x = 0; x < normalized.width; x++) {
        mean += normalized.getPixel(x, y).r.toDouble();
      }
    }
    mean /= normalized.width * normalized.height;
    var variance = 0.0;
    for (var y = 0; y < normalized.height; y++) {
      for (var x = 0; x < normalized.width; x++) {
        final value = normalized.getPixel(x, y).r.toDouble();
        variance += math.pow(value - mean, 2).toDouble();
      }
    }
    final std = math.sqrt(variance / (normalized.width * normalized.height)).clamp(1.0, double.infinity).toDouble();
    for (var y = 0; y < normalized.height; y += 2) {
      for (var x = 0; x < normalized.width; x += 2) {
        values.add((normalized.getPixel(x, y).r.toDouble() - mean) / std);
      }
    }
    return values;
  }

  double _cosine(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;
    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }

  Future<void> close() => _detector.close();
}
