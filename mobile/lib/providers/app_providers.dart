import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';
import '../services/media_scanner.dart';

final mediaScannerProvider = Provider<MediaScanner>((ref) => MediaScanner());
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final galleryProvider = FutureProvider<List<MediaItem>>((ref) => ref.read(mediaScannerProvider).scan(limit: 10000));
