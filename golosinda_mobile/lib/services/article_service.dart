import '../constants.dart';
import 'dart:convert';
import 'package:http/http.dart';
 
class ArticleService {
  List listData = [];
Future<List<Map<String, dynamic>>> getAllArticle() async {
    final response = await get(Uri.parse('$host/api/articles'));
 
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
 
      if (decoded is Map && decoded.containsKey('articles')) {
        // backend returns { "articles": [...] }
        return List<Map<String, dynamic>>.from(decoded['articles']);
      } else if (decoded is List) {
        // backend returns raw list
        return List<Map<String, dynamic>>.from(decoded);
      } else {
        throw Exception("Unexpected response format: ${response.body}");
      }
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }
 
  // Add to the article_service.dart
  Future<Map> createArticle(dynamic article) async {
    final response = await post(
      Uri.parse('$host/api/articles'),
      
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      
      body: jsonEncode(article),
      
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      Map mapData = jsonDecode(response.body);
      return mapData;
    } else {
      throw Exception(
          'Failed to create article: ${response.statusCode} ${response.body}');
    }
  }
 
  Future<Map> updateArticle(String id, dynamic article) async {
    final response = await put(
      Uri.parse('$host/api/articles/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(article),
    );
 
    if (response.statusCode == 200 || response.statusCode == 201) {
      Map mapData = jsonDecode(response.body);
      return mapData;
    } else {
      throw Exception(
          'Failed to update article: ${response.statusCode} ${response.body}');
    }
  }
}