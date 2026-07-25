import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SharingScreen extends StatefulWidget {
  const SharingScreen({super.key});
  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  final email = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String status = '';

  @override
  void dispose() {
    email.dispose(); username.dispose(); password.dispose(); super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() { busy = true; status = ''; });
    try { await action(); setState(() => status = success); } catch (error) { setState(() => status = error.toString()); } finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Account and sharing')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: username, decoration: const InputDecoration(labelText: 'Username (registration only)')),
            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 16),
            FilledButton(onPressed: busy ? null : () => _run(() => ApiService().login(email: email.text.trim(), password: password.text), 'Logged in.'), child: const Text('Log in')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: busy ? null : () => _run(() => ApiService().register(email: email.text.trim(), username: username.text.trim(), password: password.text), 'Account created. Log in next.'), child: const Text('Register')),
            const SizedBox(height: 16),
            Text(status),
            const Divider(height: 32),
            const Text('After login, friend requests, notifications, relay shares and shared albums use the deployed FastAPI backend.'),
          ],
        ),
      );
}
