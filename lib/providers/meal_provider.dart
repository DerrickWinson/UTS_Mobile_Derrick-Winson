import 'package:flutter/foundation.dart';
import '../models/meal.dart';
import '../services/meal_service.dart';

class MealProvider extends ChangeNotifier {
  final MealService _service = MealService();

  List<String> _categories = [];
  List<Meal> _baseMeals = [];
  List<Meal> _visibleMeals = [];

  String _selectedCategory = MealService.defaultCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isOffline = false;
  String _message = '';

  List<String> get categories =>
      _categories.isNotEmpty ? _categories : MealService.fallbackCategories;

  List<Meal> get visibleMeals => _visibleMeals;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  String get message => _message;

  Future<void> initialize() async {
    _categories = await _service.loadCategoriesCache();
    if (_categories.isEmpty) {
      _categories = MealService.fallbackCategories;
    }

    await loadMeals();
  }

  Future<void> loadMeals({String? category, bool showLoading = true}) async {
    final targetCategory = category ?? _selectedCategory;
    _selectedCategory = targetCategory;

    if (showLoading) {
      _isLoading = true;
      _message = '';
      notifyListeners();
    }

    try {
      final data = await _service.fetchMealsByCategory(targetCategory);
      _baseMeals = data;
      _visibleMeals = _searchQuery.trim().isEmpty
          ? data
          : _applyLocalSearch(_baseMeals, _searchQuery);

      await _service.saveMealsCache(targetCategory, data);
      await _service.saveCategoriesCache(_categories);

      _isOffline = false;
      _message = 'Menu kategori $targetCategory berhasil dimuat.';
    } catch (e) {
      _isOffline = true;
      final cached = await _service.loadMealsCache(targetCategory);

      if (cached.isNotEmpty) {
        _baseMeals = cached;
        _visibleMeals = _searchQuery.trim().isEmpty
            ? cached
            : _applyLocalSearch(_baseMeals, _searchQuery);
        _message = 'Tidak ada koneksi. Menampilkan cache terakhir.';
      } else {
        _baseMeals = [];
        _visibleMeals = [];
        _message = 'Gagal memuat data resep. Coba lagi nanti.';
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> changeCategory(String category) async {
    if (_selectedCategory == category) return;

    _searchQuery = '';
    await loadMeals(category: category);
  }

  Future<void> searchMeals(String query) async {
    _searchQuery = query;

    if (query.trim().isEmpty) {
      _visibleMeals = _baseMeals;
      _message = 'Menampilkan semua menu pada kategori terpilih.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final results = await _service.searchMeals(query);
      _visibleMeals = results
          .where((meal) =>
              meal.category.toLowerCase() == _selectedCategory.toLowerCase())
          .toList();

      _isOffline = false;
      _message = _visibleMeals.isEmpty
          ? 'Tidak ada resep yang cocok.'
          : 'Hasil pencarian ditampilkan.';
    } catch (e) {
      _isOffline = true;
      _visibleMeals = _applyLocalSearch(_baseMeals, query);
      _message = 'Pencarian memakai data cache lokal.';
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Meal> _applyLocalSearch(List<Meal> source, String query) {
    final q = query.trim().toLowerCase();

    return source.where((meal) {
      final inName = meal.name.toLowerCase().contains(q);
      final inCategory = meal.category.toLowerCase().contains(q);
      final inArea = meal.area.toLowerCase().contains(q);
      final inInstructions = meal.instructions.toLowerCase().contains(q);

      return inName || inCategory || inArea || inInstructions;
    }).toList();
  }

  bool get hasData => _visibleMeals.isNotEmpty;
}