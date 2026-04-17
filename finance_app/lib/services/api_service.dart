import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../models/expense.dart';

class ApiService {
  static const baseUrl = 'http://localhost:8000';
  static const _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  static Map<String, String> _authHeaders(String token) {
    return {
      ..._jsonHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  static Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Login failed: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['access_token'] as String;
  }

  static Future<void> register(
    String name,
    String email,
    String password, {
    String userType = 'independent',
    double monthlyIncome = 0,
    String riskProfile = 'moderate',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'user_type': userType,
        'monthly_income': monthlyIncome,
        'risk_profile': riskProfile,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
          'Registration failed: ${response.statusCode} ${response.body}');
    }
  }

  static Future<List<Category>> fetchCategories(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/category/'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Unable to load categories: ${response.statusCode} ${response.body}');
    }

    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .cast<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList();
  }

  static Future<double> fetchMonthlyIncome(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/income/monthly'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Unable to load monthly income: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['total_income'] as num).toDouble();
  }

  static Future<Map<String, double>> fetchExpenseSummary(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/expense/summary'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Unable to load expense summary: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final breakdown = <String, double>{};
    final categoryMap = data['category_breakdown'] as Map<String, dynamic>;
    categoryMap.forEach((key, value) {
      breakdown[key] = (value as num).toDouble();
    });

    return {
      'totalExpense': (data['total_expense'] as num).toDouble(),
      ...breakdown,
    };
  }

  static Future<void> addCategory(
    String token,
    String name,
    int? budgetLimit,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/category'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'name': name,
        'budget_limit': budgetLimit,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
          'Unable to create category: ${response.statusCode} ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getPortfolio(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/investment/portfolio'),
    headers: _authHeaders(token),
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Unable to load portfolio: ${response.statusCode} ${response.body}'
    );
  }

  return jsonDecode(response.body);
}

static Future<dynamic> addInvestment({
  required String investmentType,
  String? investmentName,
  double? principalAmount,
  double? rateOfReturn,
  double? quantity,
  double? buyPrice,
  String? symbol,
  required String startDate,
  required bool autoUpdate,
}) async {

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  final response = await http.post(
    Uri.parse('$baseUrl/investment'), // ✅ FIXED
    headers: _authHeaders(token),
    body: jsonEncode({
      'investment_type': investmentType,
      'investment_name': investmentName,
      'principal_amount': principalAmount,
      'rate_of_return': rateOfReturn,
      'quantity': quantity,
      'buy_price': buyPrice,
      'symbol': symbol,
      'start_date': startDate,
      'auto_update': autoUpdate,
    }),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception(
      'Unable to add investment: ${response.statusCode} ${response.body}'
    );
  }

  return jsonDecode(response.body);
}
}
