import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String selectedCategory = "Все";

  Future<List<Map<String, dynamic>>> loadDrinks() async {
    final res = await Supabase.instance.client
        .from('drinks')
        .select()
        .order('id', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  List<String> extractCategories(List<Map<String, dynamic>> drinks) {
    final set = {"Все"};
    for (var d in drinks) {
      final cat = d["category"];
      if (cat != null && cat.toString().trim().isNotEmpty) set.add(cat);
    }
    return set.toList();
  }

  Widget _glassCard({required Widget child, double padding = 16}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: child,
        ),
      ),
    );
  }

  void showDetails({
    required String name,
    required String price,
    required String category,
    required String? imageUrl,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: _glassCard(
          padding: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(imageUrl, height: 200, fit: BoxFit.cover),
                ),
              const SizedBox(height: 20),
              Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Категория: $category",
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
              Text("Цена: $price",
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text("Закрыть"),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      // 🔥 ТУТ ДОБАВИЛ БОКОВОЕ МЕНЮ
      drawer: const ModernDrawer(),

      appBar: AppBar(
        title: const Text("Меню"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Stack(
        children: [
          Container(
            constraints: const BoxConstraints.expand(),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder(
                future: loadDrinks(),
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final drinks = snapshot.data!;
                  final categories = extractCategories(drinks);

                  final filtered = selectedCategory == "Все"
                      ? drinks
                      : drinks
                          .where((d) => d['category'] == selectedCategory)
                          .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 50,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: categories.map((cat) {
                            final isSelected = cat == selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (_) =>
                                    setState(() => selectedCategory = cat),
                                selectedColor: Colors.white,
                                backgroundColor:
                                    Colors.grey.withOpacity(0.25),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 1,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final d = filtered[i];
                            final img = d['image_path'];
                            final url = img == null
                                ? null
                                : Supabase.instance.client.storage
                                    .from("drinks")
                                    .getPublicUrl(img);

                            return _drinkCard(
                              name: d["name"],
                              price: "${d["price"]} ₽",
                              category: d["category"],
                              imageUrl: url,
                              onMore: () => showDetails(
                                name: d["name"],
                                price: "${d["price"]} ₽",
                                category: d["category"],
                                imageUrl: url,
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drinkCard({
    required String name,
    required String price,
    required String category,
    required String? imageUrl,
    required VoidCallback onMore,
  }) {
    return _glassCard(
      padding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: imageUrl == null
                  ? Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(Icons.local_drink,
                            size: 70, color: Colors.white70),
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category,
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(price,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onMore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Подробнее"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
