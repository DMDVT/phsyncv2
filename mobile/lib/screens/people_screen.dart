import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/media_item.dart';
import '../models/person_album.dart';
import '../services/face_match_service.dart';
import '../services/media_scanner.dart';
import '../services/person_album_store.dart';
import 'media_collection_screen.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final _store = PersonAlbumStore();
  final _scanner = MediaScanner();
  final _nameController = TextEditingController();

  List<PersonAlbum> _albums = const <PersonAlbum>[];
  bool _loading = true;
  bool _scanning = false;
  String? _referencePath;
  int _yearsBack = 5;
  FaceScanProgress? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final albums = await _store.load();
    if (!mounted) return;
    setState(() {
      _albums = albums;
      _loading = false;
    });
  }

  Future<void> _pickReference() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    final sourcePath = result?.files.single.path;
    if (sourcePath == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final referenceDir = Directory(p.join(appDir.path, 'person_references'));
    await referenceDir.create(recursive: true);
    final extension = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final destination = p.join(referenceDir.path, '${const Uuid().v4()}$extension');
    await File(sourcePath).copy(destination);

    if (!mounted) return;
    setState(() {
      _referencePath = destination;
      _error = null;
    });
  }

  Future<void> _createAlbum() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name for the person album.');
      return;
    }
    if (_referencePath == null) {
      setState(() => _error = 'Choose a clear reference photo first.');
      return;
    }

    setState(() {
      _scanning = true;
      _error = null;
      _progress = null;
    });

    final now = DateTime.now();
    final cutoff = DateTime(now.year - _yearsBack, now.month, now.day);
    FaceMatchService? matcher;
    try {
      final candidates = await _scanner.scan(limit: 50000, from: cutoff, to: now);
      matcher = FaceMatchService();
      final matches = await matcher.findMatches(
        referencePath: _referencePath!,
        candidates: candidates,
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );

      final album = PersonAlbum(
        id: const Uuid().v4(),
        name: name,
        referencePath: _referencePath!,
        yearsBack: _yearsBack,
        assetIds: matches.map((item) => item.asset.id).toList(growable: false),
        createdAt: DateTime.now(),
      );
      final updated = <PersonAlbum>[album, ..._albums];
      await _store.save(updated);

      if (!mounted) return;
      setState(() {
        _albums = updated;
        _scanning = false;
        _progress = null;
        _referencePath = null;
        _nameController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created “$name” with ${matches.length} matching photos.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _progress = null;
        _error = error.toString();
      });
    } finally {
      await matcher?.close();
    }
  }

  Future<void> _openAlbum(PersonAlbum album) async {
    setState(() => _loading = true);
    try {
      final items = await _scanner.resolveAssetIds(album.assetIds);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MediaCollectionScreen(title: album.name, items: items),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAlbum(PersonAlbum album) async {
    final updated = _albums.where((item) => item.id != album.id).toList(growable: false);
    await _store.save(updated);
    try {
      final file = File(album.referencePath);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Album deletion should still succeed if the copied reference file is gone.
    }
    if (mounted) setState(() => _albums = updated);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text('Create a person album', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Choose one clear photo of the person. PhotoSync scans only the selected number of past years on this device and saves matching photos as a local album.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  enabled: !_scanning,
                  decoration: const InputDecoration(
                    labelText: 'Person name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _yearsBack,
                  decoration: const InputDecoration(
                    labelText: 'Search photos from the past',
                    border: OutlineInputBorder(),
                  ),
                  items: const <int>[1, 2, 3, 5, 10, 15, 20]
                      .map((years) => DropdownMenuItem<int>(
                            value: years,
                            child: Text('$years ${years == 1 ? 'year' : 'years'}'),
                          ))
                      .toList(),
                  onChanged: _scanning ? null : (value) => setState(() => _yearsBack = value ?? 5),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _scanning ? null : _pickReference,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(_referencePath == null ? 'Choose reference photo' : 'Reference photo selected'),
                ),
                if (_referencePath != null) ...<Widget>[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_referencePath!),
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        height: 120,
                        child: Center(child: Text('Unable to preview reference image')),
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                if (_scanning) ...<Widget>[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _progress == null || _progress!.total == 0
                        ? null
                        : _progress!.processed / _progress!.total,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _progress == null
                        ? 'Preparing device scan…'
                        : 'Checked ${_progress!.processed} of ${_progress!.total}; ${_progress!.matches} matches',
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _scanning ? null : _createAlbum,
                  icon: const Icon(Icons.face_retouching_natural),
                  label: const Text('Scan and create album'),
                ),
                const SizedBox(height: 28),
                Text('Saved person albums', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (_albums.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No person albums have been created yet.'),
                    ),
                  )
                else
                  ..._albums.map(
                    (album) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: File(album.referencePath).existsSync()
                              ? FileImage(File(album.referencePath))
                              : null,
                          child: File(album.referencePath).existsSync() ? null : const Icon(Icons.person),
                        ),
                        title: Text(album.name),
                        subtitle: Text('${album.assetIds.length} photos · past ${album.yearsBack} years'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') _deleteAlbum(album);
                          },
                          itemBuilder: (_) => const <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(value: 'delete', child: Text('Delete album')),
                          ],
                        ),
                        onTap: () => _openAlbum(album),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Matching is performed on-device. Photo metadata is used to limit the date range; identity is estimated from detected face appearance, not from names stored in photo metadata.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
    );
  }
}
