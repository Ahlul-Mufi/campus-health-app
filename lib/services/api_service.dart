import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/place.dart';

class ApiService {
  static const String baseUrl =
      'https://campus-healt-api-production.up.railway.app';

  Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/api/categories'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Category.fromJson(e)).toList();
    }
    throw Exception('Failed to load categories');
  }

  Future<List<Place>> getPlaces({String? category}) async {
    final uri = Uri.parse('$baseUrl/api/places').replace(
      queryParameters: category != null ? {'category': category} : null,
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data = body['data'];
      return data.map((e) => Place.fromJson(e)).toList();
    }
    throw Exception('Failed to load places');
  }

  Future<Place> getPlaceById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/places/$id'));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return Place.fromJson(body['data']);
    }
    throw Exception('Failed to load place');
  }
}