import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;

  String? get token => _token;

  bool get isAuthenticated => _token != null;

  Future<void> login(String email, String password) async {
    final accessToken = await ApiService.login(email, password);
    _token = accessToken;
    notifyListeners();
  }

  Future<void> register(
    String name,
    String email,
    String password,
  ) async {
    await ApiService.register(name, email, password);
  }

  void logout() {
    _token = null;
    notifyListeners();
  }
}
