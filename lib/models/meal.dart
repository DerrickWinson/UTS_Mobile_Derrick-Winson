class Meal {
  final String id;
  final String name;
  final String category;
  final String area;
  final String thumbnail;
  final String instructions;
  final String youtube;
  final List<String> ingredientLines;

  Meal({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.thumbnail,
    required this.instructions,
    required this.youtube,
    required this.ingredientLines,
  });

  factory Meal.fromSummaryJson(Map<String, dynamic> json) {
    return Meal(
      id: (json['idMeal'] ?? '').toString(),
      name: (json['strMeal'] ?? 'Untitled').toString(),
      category: (json['strCategory'] ?? '').toString(),
      area: (json['strArea'] ?? '').toString(),
      thumbnail: (json['strMealThumb'] ?? '').toString(),
      instructions: (json['strInstructions'] ?? '').toString(),
      youtube: (json['strYoutube'] ?? '').toString(),
      ingredientLines: const [],
    );
  }

  factory Meal.fromDetailJson(Map<String, dynamic> json) {
    final ingredients = <String>[];

    for (int i = 1; i <= 20; i++) {
      final ingredient = (json['strIngredient$i'] ?? '').toString().trim();
      final measure = (json['strMeasure$i'] ?? '').toString().trim();

      if (ingredient.isNotEmpty) {
        final line = [measure, ingredient].where((e) => e.isNotEmpty).join(' ');
        ingredients.add(line);
      }
    }

    return Meal(
      id: (json['idMeal'] ?? '').toString(),
      name: (json['strMeal'] ?? 'Untitled').toString(),
      category: (json['strCategory'] ?? '').toString(),
      area: (json['strArea'] ?? '').toString(),
      thumbnail: (json['strMealThumb'] ?? '').toString(),
      instructions: (json['strInstructions'] ?? '').toString(),
      youtube: (json['strYoutube'] ?? '').toString(),
      ingredientLines: ingredients,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'area': area,
      'thumbnail': thumbnail,
      'instructions': instructions,
      'youtube': youtube,
      'ingredientLines': ingredientLines,
    };
  }

  factory Meal.fromCache(Map<String, dynamic> json) {
    return Meal(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Untitled').toString(),
      category: (json['category'] ?? '').toString(),
      area: (json['area'] ?? '').toString(),
      thumbnail: (json['thumbnail'] ?? '').toString(),
      instructions: (json['instructions'] ?? '').toString(),
      youtube: (json['youtube'] ?? '').toString(),
      ingredientLines: (json['ingredientLines'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}