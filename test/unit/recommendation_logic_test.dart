import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplikasi/utils/recommendation_logic.dart';

void main() {
  group('Unit Test - Recommendation Feature', () {
    test('Berhasil mengambil data rekomendasi', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');

        return http.Response(
          jsonEncode({
            "recommendations": [
              {
                "item_id": 1,
                "fitting_name": "kemeja",
                "image_url": "img.jpg",
                "match_score": 85
              }
            ],
            "total_match_score": 85,
            "summary": "Gaya kamu sudah cocok",
          }),
          200,
        );
      });

      final result = await RecommendationLogic.fetchRecommendation(
        userId: 1,
        style: "formal",
        gender: "pria",
        source: "lemari",
        client: mockClient,
      );

      expect(result["recommendations"], isNotEmpty);
      expect(result["total_match_score"], 85);
      expect(result["summary"], isNotEmpty);
    });

    test('Gagal mengambil rekomendasi jika server error', () async {
      final mockClient = MockClient((request) async {
        return http.Response("Server Error", 500);
      });

      expect(
        () async => RecommendationLogic.fetchRecommendation(
          userId: 1,
          style: "casual",
          gender: "wanita",
          source: "online",
          client: mockClient,
        ),
        throwsException,
      );
    });
  });
}
