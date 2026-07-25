import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VaultService {
  static const String _pinKey = 'vault_pin_hash';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String _hash(String value) => sha256.convert(utf8.encode(value)).toString();
  Future<bool> hasPin() => _storage.containsKey(key: _pinKey);
  Future<bool> unlock(String pin) async => await _storage.read(key: _pinKey) == _hash(pin);
  Future<void> setPin(String pin) async {
    if (!RegExp(r'^\d{4,8}$').hasMatch(pin)) throw ArgumentError('PIN must contain 4 to 8 digits.');
    await _storage.write(key: _pinKey, value: _hash(pin));
  }
}
