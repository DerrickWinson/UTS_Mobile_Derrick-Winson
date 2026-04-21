import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal.dart';

class MealService {
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  static const String defaultCategory = 'Seafood';

  static const List<String> fallbackCategories = [
    'Beef',
    'Breakfast',
    'Chicken',
    'Dessert',
    'Goat',
    'Lamb',
    'Miscellaneous',
    'Pasta',
    'Pork',
    'Seafood',
    'Side',
    'Starter',
    'Vegan',
    'Vegetarian',
  ];

  Future<List<String>> fetchCategories() async {
    final uri = Uri.parse('$baseUrl/categories.php');
    final response = await http.get(uri).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Failed to load categories');
    }

    final decoded = jsonDecode(response.body);
    final categories = decoded['categories'] as List<dynamic>?;

    if (categories == null) return [];

    return categories
        .map((item) => (item as Map<String, dynamic>)['strCategory'].toString())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<List<Meal>> fetchMealsByCategory(String category) async {
    final uri = Uri.parse('$baseUrl/filter.php?c=$category');
    final response = await http.get(uri).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Failed to load meals');
    }

    final decoded = jsonDecode(response.body);
    final meals = decoded['meals'] as List<dynamic>?;

    if (meals == null) return [];

    return meals
        .map((item) => Meal.fromSummaryJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Meal>> searchMeals(String query) async {
    final uri = Uri.parse('$baseUrl/search.php?s=$query');
    final response = await http.get(uri).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Failed to search meals');
    }

    final decoded = jsonDecode(response.body);
    final meals = decoded['meals'] as List<dynamic>?;

    if (meals == null) return [];

    return meals
        .map((item) => Meal.fromDetailJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Meal?> fetchMealDetail(String id) async {
    final uri = Uri.parse('$baseUrl/lookup.php?i=$id');
    final response = await http.get(uri).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Failed to load meal detail');
    }

    final decoded = jsonDecode(response.body);
    final meals = decoded['meals'] as List<dynamic>?;

    if (meals == null || meals.isEmpty) return null;

    return Meal.fromDetailJson(meals.first as Map<String, dynamic>);
  }

  Future<void> saveCategoriesCache(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('meal_categories_cache', jsonEncode(categories));
  }

  Future<List<String>> loadCategoriesCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('meal_categories_cache');
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded.map((e) => e.toString()).toList();
  }

  Future<void> saveMealsCache(String category, List<Meal> meals) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = meals.map((m) => m.toJson()).toList();
    await prefs.setString('meal_cache_$category', jsonEncode(cacheData));
  }

  Future<List<Meal>> loadMealsCache(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('meal_cache_$category');

    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .map((item) => Meal.fromCache(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMealDetailCache(Meal meal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('meal_detail_${meal.id}', jsonEncode(meal.toJson()));
  }

  Future<Meal?> loadMealDetailCache(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('meal_detail_$id');

    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;

    return Meal.fromCache(decoded);
  }
}