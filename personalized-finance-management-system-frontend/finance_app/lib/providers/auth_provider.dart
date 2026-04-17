import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1500));
    _user = User(
      name: 'Harsh',
      email: email,
    );
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1500));
    _user = User(name: name, email: email);
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
