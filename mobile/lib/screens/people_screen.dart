import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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
  final PersonAlbumStore _store = PersonAlbumStore();
  final MediaScanner _scanner = MediaScanner();
  final TextEditingController _nameController = TextEditingController();

  List<PersonAlbum> _albums = <PersonAlbum>[];
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
    try {
      final List<PersonAlbum> albums = await _store.load();

      if (!mounted) {
        return;
      }

      setState(() {
        _albums = albums;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = 'Unable to load person albums: $error';
      });
    }
  }

  Future<void> _pickReference() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
      );

      final String? sourcePath = result?.files.single.path;

      if (sourcePath == null) {
        return;
      }

      final Directory appDirectory =
          await getApplicationDocumentsDirectory();

      final Directory referenceDirectory = Directory(
        p.join(appDirectory.path, 'person_references'),
      );

      await referenceDirectory.create(recursive: true);

      final String originalExtension = p.extension(sourcePath);
      final String extension =
          originalExtension.isEmpty ? '.jpg' : originalExtension;

      final String destinationPath = p.join(
        referenceDirectory.path,
        '${const Uuid().v4()}$extension',
      );

      await File(sourcePath).copy(destinationPath);

      if (!mounted) {
        return;
      }

      setState(() {
        _referencePath = destinationPath;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Unable to select the reference image: $error';
      });
    }
  }

  Future<void> _createAlbum() async {
    final String name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _error = 'Enter a name for the person.';
      });
      return;
    }

    final String? referencePath = _referencePath;

    if (referencePath == null) {
      setState(() {
        _error = 'Choose a clear reference photo first.';
      });
      return;
    }

    setState(() {
      _scanning = true;
      _error = null;
      _progress = null;
    });

    final DateTime now = DateTime.now();
    final DateTime cutoff = DateTime(
      now.year - _yearsBack,
      now.month,
      now.day,
    );

    FaceMatchService? matcher;

    try {
      final candidates = await _scanner.scan(
        limit: 50000,
        from: cutoff,
        to: now,
      );

      matcher = FaceMatchService();

      final matches = await matcher.findMatches(
        referencePath: referencePath,
        candidates: candidates,
        onProgress: (FaceScanProgress progress) {
          if (!mounted) {
            return;
          }

          setState(() {
            _progress = progress;
          });
        },
      );

      final PersonAlbum album = PersonAlbum(
        id: const Uuid().v4(),
        name: name,
        referencePath: referencePath,
        yearsBack: _yearsBack,
        assetIds: matches
            .map((item) => item.asset.id)
            .toList(growable: false),
        createdAt: DateTime.now(),
      );

      final List<PersonAlbum> updatedAlbums = <PersonAlbum>[
        album,
        ..._albums,
      ];

      await _store.save(updatedAlbums);

      if (!mounted) {
        return;
      }

      setState(() {
        _albums = updatedAlbums;
        _scanning = false;
        _progress = null;
        _referencePath = null;
        _nameController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Created "$name" with ${matches.length} matching photos.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _scanning = false;
        _progress = null;
        _error = 'Unable to complete the face scan: $error';
      });
    } finally {
      await matcher?.close();
    }
  }

  Future<void> _openAlbum(PersonAlbum album) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _scanner.resolveAssetIds(album.assetIds);

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return MediaCollectionScreen(
              title: album.name,
              items: items,
            );
          },
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Unable to open this album: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _deleteAlbum(PersonAlbum album) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete person album?'),
          content: Text(
            'This removes "${album.name}" from PhotoSync. '
            'It does not delete the original photos.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final List<PersonAlbum> updatedAlbums = _albums
        .where((PersonAlbum item) => item.id != album.id)
        .toList(growable: false);

    try {
      await _store.save(updatedAlbums);

      final File referenceFile = File(album.referencePath);

      if (await referenceFile.exists()) {
        await referenceFile.delete();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _albums = updatedAlbums;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Unable to delete the person album: $error';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildReferencePreview() {
    final String? path = _referencePath;

    if (path == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(path),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return const SizedBox(
              height: 120,
              child: Center(
                child: Text('Unable to preview the reference image.'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgress() {
    if (!_scanning) {
      return const SizedBox.shrink();
    }

    final FaceScanProgress? progress = _progress;

    final double? progressValue =
        progress == null || progress.total == 0
            ? null
            : progress.processed / progress.total;

    final String message = progress == null
        ? 'Preparing device scan…'
        : 'Checked ${progress.processed} of ${progress.total}; '
            '${progress.matches} matches';

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LinearProgressIndicator(value: progressValue),
          const SizedBox(height: 8),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildSavedAlbums() {
    if (_albums.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No person albums have been created yet.'),
        ),
      );
    }

    return Column(
      children: _albums.map((PersonAlbum album) {
        final File referenceFile = File(album.referencePath);
        final bool referenceExists = referenceFile.existsSync();

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  referenceExists ? FileImage(referenceFile) : null,
              child: referenceExists
                  ? null
                  : const Icon(Icons.person_outline),
            ),
            title: Text(album.name),
            subtitle: Text(
              '${album.assetIds.length} photos · '
              'past ${album.yearsBack} '
              '${album.yearsBack == 1 ? 'year' : 'years'}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (String value) {
                if (value == 'delete') {
                  _deleteAlbum(album);
                }
              },
              itemBuilder: (BuildContext context) {
                return const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete album'),
                  ),
                ];
              },
            ),
            onTap: () {
              _openAlbum(album);
            },
          ),
        );
      }).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('People'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Create a person album',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a clear reference photo. PhotoSync scans photos '
            'from the selected number of previous years and saves likely '
            'matches as a local album.',
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
            initialValue: _yearsBack,
            decoration: const InputDecoration(
              labelText: 'Search photos from the past',
              border: OutlineInputBorder(),
            ),
            items: const <int>[1, 2, 3, 5, 10, 15, 20]
                .map(
                  (int years) => DropdownMenuItem<int>(
                    value: years,
                    child: Text(
                      '$years ${years == 1 ? 'year' : 'years'}',
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: _scanning
                ? null
                : (int? value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _yearsBack = value;
                    });
                  },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _scanning ? null : _pickReference,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(
              _referencePath == null
                  ? 'Choose reference photo'
                  : 'Change reference photo',
            ),
          ),
          _buildReferencePreview(),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          _buildProgress(),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _scanning ? null : _createAlbum,
            icon: const Icon(Icons.face_retouching_natural),
            label: Text(
              _scanning ? 'Scanning photos…' : 'Scan and create album',
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Saved person albums',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _buildSavedAlbums(),
          const SizedBox(height: 12),
          const Text(
            'Matching is performed on the device. Photo metadata limits '
            'the date range, while detected facial appearance is used to '
            'estimate possible matches.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
