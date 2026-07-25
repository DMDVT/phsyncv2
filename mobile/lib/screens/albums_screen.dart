import 'package:flutter/material.dart';
import '../models/album_info.dart';
import '../services/media_scanner.dart';
import 'duplicates_screen.dart';
import 'memories_screen.dart';
import 'smart_albums_screen.dart';

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Albums')),
        body: ListView(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('Smart albums', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.copy_all),
              title: const Text('Duplicates'),
              subtitle: const Text('Find identical and near-identical photos on-device'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DuplicatesScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Places'),
              subtitle: const Text('Albums created from GPS metadata'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SmartAlbumsScreen(mode: SmartAlbumMode.location)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Dates'),
              subtitle: const Text('Albums grouped by month and year'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SmartAlbumsScreen(mode: SmartAlbumMode.date)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Memories'),
              subtitle: const Text('On this day and yearly collections'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MemoriesScreen())),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('Device albums', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            FutureBuilder<List<AlbumInfo>>(
              future: MediaScanner().albums(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
                }
                final albums = snapshot.data ?? const <AlbumInfo>[];
                if (albums.isEmpty) return const ListTile(title: Text('No device albums available.'));
                return Column(
                  children: albums
                      .map((album) => ListTile(
                            leading: const Icon(Icons.photo_album),
                            title: Text(album.path.name),
                            trailing: Text('${album.count}'),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      );
}
