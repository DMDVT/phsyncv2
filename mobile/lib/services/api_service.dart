import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  ApiService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 30)));

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://phsync-production.up.railway.app',
  );

  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _attachToken() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Map<String, dynamic>> health() async {
    final response = await _dio.get<Map<String, dynamic>>('/health');
    return response.data ?? <String, dynamic>{};
  }

  Future<void> login({required String email, required String password}) async {
    final response = await _dio.post<Map<String, dynamic>>('/auth/login', data: <String, dynamic>{'email_or_username': email, 'password': password});
    final data = response.data ?? <String, dynamic>{};
    final token = data['access_token'] as String?;
    if (token == null || token.isEmpty) throw StateError('Server did not return an access token.');
    await _storage.write(key: 'access_token', value: token);
  }

  Future<void> register({required String email, required String username, required String password}) async {
    final response = await _dio.post<Map<String, dynamic>>('/auth/register', data: <String, dynamic>{'email': email, 'username': username, 'password': password});
    final token = response.data?['access_token'] as String?;
    if (token != null && token.isNotEmpty) await _storage.write(key: 'access_token', value: token);
  }

  Future<List<dynamic>> friends() async {
    await _attachToken();
    final response = await _dio.get<List<dynamic>>('/friends');
    return response.data ?? <dynamic>[];
  }

  Future<List<dynamic>> notifications() async {
    await _attachToken();
    final response = await _dio.get<List<dynamic>>('/notifications');
    return response.data ?? <dynamic>[];
  }

  Future<void> logout() => _storage.delete(key: 'access_token');
}
