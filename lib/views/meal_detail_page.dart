import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../services/meal_service.dart';

class MealDetailPage extends StatefulWidget {
  final Meal meal;

  const MealDetailPage({super.key, required this.meal});

  @override
  State<MealDetailPage> createState() => _MealDetailPageState();
}

class _MealDetailPageState extends State<MealDetailPage> {
  late Future<Meal?> _detailFuture;
  final MealService _service = MealService();

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<Meal?> _loadDetail() async {
    try {
      final detail = await _service.fetchMealDetail(widget.meal.id);
      if (detail != null) {
        await _service.saveMealDetailCache(detail);
        return detail;
      }
      return widget.meal;
    } catch (e) {
      final cached = await _service.loadMealDetailCache(widget.meal.id);
      return cached ?? widget.meal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meal.name),
      ),
      body: FutureBuilder<Meal?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final meal = snapshot.data!;
          final poster = meal.thumbnail.isNotEmpty
              ? meal.thumbnail
              : 'https://via.placeholder.com/300x450?text=No+Image';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      poster,
                      height: 320,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 320,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 72),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  meal.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (meal.category.isNotEmpty) _chip('Kategori: ${meal.category}'),
                    if (meal.area.isNotEmpty) _chip('Area: ${meal.area}'),
                    if (meal.id.isNotEmpty) _chip('ID: ${meal.id}'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Instruksi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  meal.instructions.isNotEmpty
                      ? meal.instructions
                      : 'Instruksi belum tersedia.',
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bahan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (meal.ingredientLines.isEmpty)
                  const Text('Bahan belum tersedia.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: meal.ingredientLines.map(_chip).toList(),
                  ),
                const SizedBox(height: 16),
                if (meal.youtube.isNotEmpty) ...[
                  const Text(
                    'YouTube',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(meal.youtube),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String text) {
    return Chip(label: Text(text));
  }
}