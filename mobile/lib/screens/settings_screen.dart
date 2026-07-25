import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          children: <Widget>[
            const ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('Local-first media'), subtitle: Text('Device photos are not uploaded unless you explicitly share them.')),
            ListTile(leading: const Icon(Icons.ios_share), title: const Text('Sharing and account'), onTap: () => context.push('/sharing')),
            ListTile(leading: const Icon(Icons.lock_outline), title: const Text('Private vault'), onTap: () => context.push('/vault')),
            ListTile(leading: const Icon(Icons.storage), title: const Text('Storage analytics'), onTap: () => context.push('/storage')),
            ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('Memories'), onTap: () => context.push('/memories')),
            ListTile(
              leading: const Icon(Icons.cloud_done_outlined),
              title: const Text('Backend health'),
              subtitle: Text(ApiService.baseUrl),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final health = await ApiService().health();
                  messenger.showSnackBar(SnackBar(content: Text('Online: ${health['status'] ?? 'ok'}')));
                } catch (error) {
                  messenger.showSnackBar(SnackBar(content: Text('Backend unavailable: $error')));
                }
              },
            ),
          ],
        ),
      );
}
