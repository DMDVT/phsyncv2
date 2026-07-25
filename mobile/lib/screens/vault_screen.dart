import 'package:flutter/material.dart';
import '../services/vault_service.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});
  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final controller = TextEditingController();
  final service = VaultService();
  bool unlocked = false;
  String? error;

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Private vault')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: unlocked
              ? const Center(child: Text('Vault unlocked. Select hidden media integration during device testing.'))
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                  const Icon(Icons.lock, size: 64),
                  TextField(controller: controller, keyboardType: TextInputType.number, obscureText: true, decoration: InputDecoration(labelText: '4–8 digit PIN', errorText: error)),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: () async {
                    try {
                      final hasPin = await service.hasPin();
                      if (!hasPin) await service.setPin(controller.text);
                      final ok = await service.unlock(controller.text);
                      setState(() { unlocked = ok; error = ok ? null : 'Incorrect PIN'; });
                    } catch (exception) {
                      setState(() => error = exception.toString());
                    }
                  }, child: const Text('Unlock or create')),
                ]),
        ),
      );
}
