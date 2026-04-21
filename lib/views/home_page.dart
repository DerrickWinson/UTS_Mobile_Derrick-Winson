import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/meal_card.dart';
import '../widgets/shimmer_loading.dart';
import 'meal_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<void> _bootstrap;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<MealProvider>();
    _bootstrap = provider.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LabRecipe'),
      ),
      body: FutureBuilder(
        future: _bootstrap,
        builder: (context, snapshot) {
          return Consumer<MealProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.visibleMeals.isEmpty) {
                return const ShimmerLoading();
              }

              return RefreshIndicator(
                onRefresh: () => provider.loadMeals(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildTopInfo(context, provider),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(context, provider),
                    const SizedBox(height: 16),
                    _buildSearchField(context, provider),
                    const SizedBox(height: 16),
                    if (provider.message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          provider.message,
                          style: TextStyle(
                            color: provider.isOffline ? Colors.orange : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (!provider.isLoading &&
                        provider.visibleMeals.isEmpty &&
                        provider.message.contains('Gagal'))
                      ErrorState(
                        title: 'Data gagal dimuat',
                        subtitle: 'Coba refresh atau pilih kategori lain.',
                        onRetry: () => provider.loadMeals(),
                      )
                    else if (!provider.isLoading && provider.visibleMeals.isEmpty)
                      const EmptyState(
                        title: 'Resep tidak ditemukan',
                        subtitle: 'Coba kata kunci lain atau ganti kategori.',
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.visibleMeals.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.70,
                        ),
                        itemBuilder: (context, index) {
                          final meal = provider.visibleMeals[index];
                          return MealCard(
                            meal: meal,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MealDetailPage(meal: meal),
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTopInfo(BuildContext context, MealProvider provider) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.restaurant, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.isOffline ? 'Mode Offline' : 'Mode Online',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.isOffline
                        ? 'Menampilkan data terakhir yang tersimpan'
                        : 'Data resep siap dicari dan difilter',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context, MealProvider provider) {
    return DropdownButtonFormField<String>(
      initialValue: provider.selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Pilih kategori',
      ),
      items: provider.categories
          .map(
            (category) => DropdownMenuItem(
              value: category,
              child: Text(category),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          _searchController.clear();
          context.read<MealProvider>().changeCategory(value);
        }
      },
    );
  }

  Widget _buildSearchField(BuildContext context, MealProvider provider) {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        labelText: 'Cari resep',
        hintText: 'Nama menu, area, atau bahan...',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (value) {
        context.read<MealProvider>().searchMeals(value);
      },
    );
  }
}