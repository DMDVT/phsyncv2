import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/person_album.dart';

class PersonAlbumStore {
  static const _key = 'person_albums_v1';

  Future<List<PersonAlbum>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const <PersonAlbum>[];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((item) => PersonAlbum.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> save(List<PersonAlbum> albums) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(albums.map((album) => album.toJson()).toList()));
  }
}
