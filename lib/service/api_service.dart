import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../constants.dart';

class ApiService {

  // Método para obtener todas las categorías
  static Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Category.fromJson(json)).toList();
    } else { 
      throw Exception('Error al cargar las categorías');
    }
  }

  // Método para obtener una categoría con productGroups y products
  static Future<Category> fetchCategoryWithProducts(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/categories/$id'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return Category.fromJson(json);
    } else {
      throw Exception('Error al cargar la categoría con productos');
    }
  }
}
