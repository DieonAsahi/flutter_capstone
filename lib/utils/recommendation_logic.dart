import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aplikasi/services/api_config.dart';

class RecommendationLogic {
  static Future<Map<String, dynamic>> fetchRecommendation({
    required int userId,
    required String style,
    required String gender,
    required String source,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();

    final response = await httpClient.post(
      Uri.parse("${ApiConfig.baseUrl}/api/recommendation/final"),
      headers: ApiConfig.headers,
      body: jsonEncode({
        "user_id": userId,
        "style": style,
        "gender": gender,
        "source": source,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load recommendation");
    }
  }
}
