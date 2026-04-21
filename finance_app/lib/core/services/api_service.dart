import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://localhost:8000";

  static Future<bool> login(String email, String password) async {
    try {
      print("Sending login request...");

      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data["access_token"]);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Login Error: $e");
      return false;
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }

  static Future<bool> register(
  String name,
  String email,
  String password,
) async {
  try {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "user_type": "independent",
        "monthly_income": 0,
        "risk_profile": "medium"
      }),
    );

    print(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    print("Register error: $e");
    return false;
  }
}

  // ✅ THIS METHOD MUST BE INSIDE THE CLASS
  static Future<Map<String, dynamic>?> getWithAuth(String endpoint) async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Error: ${response.body}");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> postWithAuth(
  String endpoint,
  Map<String, dynamic> body,
) async {

  final token = await getToken();

  final response = await http.post(
    Uri.parse("$baseUrl$endpoint"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
    body: jsonEncode(body),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    print("POST $endpoint failed: ${response.statusCode}");
    print(response.body);
    return null;
  }
}

  static Future<Map<String, dynamic>?> getProfile() async {
    // Since /auth/me doesn't exist, return mock data
    // In production, you'd need to implement a user profile endpoint
    try {
      final token = await getToken();
      return {
        "name": "User",
        "email": "user@example.com",
        "user_type": "independent",
        "monthly_income": 0,
        "risk_profile": "medium"
      };
    } catch (e) {
      return null;
    }
  }

  // ==================== EXPENSE ====================
  static Future<Map<String, dynamic>?> addExpense({
    required double amount,
    required String description,
    required String date,
    int? categoryId,
  }) async {
    return await postWithAuth("/expense", {
      "amount": amount,
      "description": description,
      "date": date,
      "category_id": categoryId,
    });
  }

  static Future<List<dynamic>?> getExpenses() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse("$baseUrl/expense/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        }
        if (data is Map<String, dynamic> && data['expenses'] is List) {
          return data['expenses'] as List<dynamic>;
        }
        return data == null ? null : [data];
      }
      return null;
    } catch (e) {
      print("Error fetching expenses: $e");
      return null;
    }
  }

  // ==================== INCOME ====================
  static Future<Map<String, dynamic>?> addIncome({
    required double amount,
    required String source,
    required String date,
    bool recurring = false,
  }) async {
    return await postWithAuth("/income", {
      "amount": amount,
      "source": source,
      "date": date,
      "recurring": recurring,
    });
  }

  static Future<Map<String, dynamic>?> getMonthlyIncome() async {
    return await getWithAuth("/income/monthly");
  }

  // ==================== CATEGORY ====================
  static Future<List<dynamic>?> getCategories() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse("$baseUrl/category/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        }
        if (data is Map<String, dynamic> && data['categories'] is List) {
          return data['categories'] as List<dynamic>;
        }
        return data == null ? null : [data];
      }
      return null;
    } catch (e) {
      print("Error fetching categories: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> addCategory({
    required String name,
    double? budgetLimit,
  }) async {
    return await postWithAuth("/category", {
      "name": name,
      "budget_limit": budgetLimit,
    });
  }

  // ==================== GOAL ====================
  static Future<Map<String, dynamic>?> createGoal({
    required String name,
    required double targetAmount,
    required String deadline,
    required int priority,
  }) async {
    return await postWithAuth("/goal", {
      "name": name,
      "target_amount": targetAmount,
      "deadline": deadline,
      "priority": priority,
    });
  }

  static Future<List<dynamic>?> getGoals() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse("$baseUrl/goal/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [data];
      }
      return null;
    } catch (e) {
      print("Error fetching goals: $e");
      return null;
    }
  }

  static Future<List<dynamic>?> getGoalProgress() async {
    final data = await getWithAuth("/goal/progress");
    return data != null ? data as List : null;
  }

  static Future<Map<String, dynamic>?> getGoalSummary() async {
    return await getWithAuth("/goal/summary");
  }

  static Future<Map<String, dynamic>?> getGoalDetail(int goalId) async {
    return await getWithAuth("/goal/$goalId");
  }

  static Future<Map<String, dynamic>?> contributeToGoal({
    required int goalId,
    required double amount,
  }) async {
    return await postWithAuth("/goal/$goalId/contribute", {
      "amount": amount,
    });
  }

  static Future<Map<String, dynamic>?> linkInvestmentToGoal({
    required int goalId,
    required int investmentId,
  }) async {
    return await postWithAuth("/goal/$goalId/link-investment", {
      "investment_id": investmentId,
    });
  }

  // ==================== INVESTMENT ====================
  static Future<Map<String, dynamic>?> addInvestment({
  required String investmentType,
  String? investmentName,
  double? principalAmount,
  double? rateOfReturn,
  double? quantity,   // ✅ FIXED
  double? buyPrice,
  String? symbol,
  required String startDate,
  bool autoUpdate = true,
}) async {
  return await postWithAuth("/investment", {
    "investment_type": investmentType,
    if (investmentName != null) "investment_name": investmentName,
    if (principalAmount != null) "principal_amount": principalAmount,
    if (rateOfReturn != null) "rate_of_return": rateOfReturn,
    if (quantity != null) "quantity": quantity,
    if (buyPrice != null) "buy_price": buyPrice,
    if (symbol != null) "symbol": symbol,
    "start_date": startDate,
    "auto_update": autoUpdate,
  });
}

  static Future<List<dynamic>?> getInvestments() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse("$baseUrl/investment/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [data];
      }
      return null;
    } catch (e) {
      print("Error fetching investments: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getPortfolio() async {
    return await getWithAuth("/investment/portfolio");
  }

  static Future<Map<String, dynamic>?> getInvestmentAnalytics() async {
  return await getWithAuth("/investment/analytics");
}

  static Future<Map<String, dynamic>?> sellInvestment({
    required int investmentId,
    required double sellPrice,
  }) async {
    return await postWithAuth("/investment/sell/$investmentId", {
      "sell_price": sellPrice,
    });
  }

  // ==================== DEBT ====================
  static Future<Map<String, dynamic>?> addDebt({
    required String debtType,
    required double principalAmount,
    required double emiAmount,
    required double interestRate,
    required String dueDate,
  }) async {
    return await postWithAuth("/debt", {
      "debt_type": debtType,
      "principal_amount": principalAmount,
      "emi_amount": emiAmount,
      "interest_rate": interestRate,
      "due_date": dueDate,
    });
  }

  static Future<Map<String, dynamic>?> addDebtPayment({
    required int debtId,
    required double amount,
    String? paymentDate,
  }) async {
    return await postWithAuth("/debt/$debtId/payment", {
      "amount": amount,
      if (paymentDate != null) "payment_date": paymentDate,
    });
  }

  static Future<List<dynamic>?> getDebts() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse("$baseUrl/debt"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [data];
      }
      return null;
    } catch (e) {
      print("Error fetching debts: $e");
      return null;
    }
  }

  // ==================== INSIGHTS ====================
  static Future<Map<String, dynamic>?> getMonthlySummary({
    int? month,
    int? year,
  }) async {
    String endpoint = "/insights/summary";
    if (month != null && year != null) {
      endpoint += "?month=$month&year=$year";
    }
    return await getWithAuth(endpoint);
  }

  static Future<Map<String, dynamic>?> getCategoryAnalysis({
    int? month,
    int? year,
  }) async {
    String endpoint = "/insights/category";
    if (month != null && year != null) {
      endpoint += "?month=$month&year=$year";
    }
    return await getWithAuth(endpoint);
  }

  static Future<List<dynamic>?> getRecommendations() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse("$baseUrl/insights/recommendations"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [data];
      }
      return null;
    } catch (e) {
      print("Error fetching recommendations: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getMonthlyTrend({required int year}) async {
    return await getWithAuth("/insights/trend?year=$year");
  }

  // ==================== HEALTH SCORE ====================
  static Future<Map<String, dynamic>?> getHealthScore() async {
    return await getWithAuth("/health/score");
  }

  // ==================== ALERTS ====================
  static Future<List<dynamic>?> getAlerts() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse("$baseUrl/alerts/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [data];
      }
      return null;
    } catch (e) {
      print("Error fetching alerts: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> generateAlerts() async {
    return await postWithAuth("/alerts/generate", {});
  }

  // ==================== UPDATE METHODS ====================
  static Future<Map<String, dynamic>?> putWithAuth(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print(response.body);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> deleteWithAuth(String endpoint) async {
    final token = await getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return response.statusCode == 204 ? {} : jsonDecode(response.body);
    } else {
      print(response.body);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getExpenseSummary() async {
    return await getWithAuth("/expense/summary");
  }

  static Future<List<dynamic>?> getExpensesByCategory(int categoryId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse("$baseUrl/expense/?category_id=$categoryId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        }
        if (data is Map<String, dynamic> && data['expenses'] is List) {
          return data['expenses'] as List<dynamic>;
        }
        return data == null ? null : [data];
      }

      return null;
    } catch (e) {
      print("Error fetching category expenses: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> setCategoryLimit({
    required int categoryId,
    required double limit,
  }) async {
    return await postWithAuth("/category/limit", {
      "category_id": categoryId,
      "limit": limit,
    });
  }

}
