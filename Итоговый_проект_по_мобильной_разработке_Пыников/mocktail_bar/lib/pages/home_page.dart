import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // -------------------------------------------------------------
  // Загрузка популярных напитков из БД (3 самых дорогих / популярных)
  // -------------------------------------------------------------
  Future<List<Map<String, dynamic>>> _loadPopular() async {
    final res = await Supabase.instance.client
        .from('drinks')
        .select()
        .order('price', ascending: false)
        .limit(3);

    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const ModernDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Milk & Mocktails",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),

      // -------------------------------------------------------------
      // ФОН + адаптивный контент
      // -------------------------------------------------------------
      body: Stack(
        children: [
          // ---------------- ФОН НА ПОЛНЫЙ ЭКРАН ----------------
          Container(
            constraints: const BoxConstraints.expand(),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF3F2B96),
                  Color(0xFF5E60CE),
                  Color(0xFF64DFDF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Размытые круги
          Positioned(
            top: -120,
            left: -80,
            child: _blurCircle(300, Colors.pinkAccent.withOpacity(0.4)),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: _blurCircle(350, Colors.cyanAccent.withOpacity(0.35)),
          ),

          // ---------------- КОНТЕНТ ----------------
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -------------------------------------------------
                      // Заголовок
                      // -------------------------------------------------
                      const Text(
                        'Открой мир\nбезалкогольных коктейлей',
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _glassCard(
                        child: const Padding(
                          padding: EdgeInsets.all(14.0),
                          child: Text(
                            "Мы готовим натуральные напитки: молочные коктейли, фруктовые миксы и авторские рецепты.\nМеню обновляется каждый день.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 35),

                      // -------------------------------------------------
                      // Популярные позиции
                      // -------------------------------------------------
                      const Text(
                        "Популярные позиции",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      FutureBuilder(
                        future: _loadPopular(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child:
                                    CircularProgressIndicator(color: Colors.white));
                          }

                          final drinks = snapshot.data!;

                          if (drinks.isEmpty) {
                            return const Text("Нет напитков",
                                style: TextStyle(color: Colors.white70));
                          }

                          return Column(
                            children: drinks.map((d) {
                              final imagePath = d['image_path'];
                              final imageUrl =
                                  imagePath == null || imagePath.isEmpty
                                      ? null
                                      : Supabase.instance.client.storage
                                          .from("drinks")
                                          .getPublicUrl(imagePath);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _drinkCard(
                                  name: d["name"],
                                  price: "${d["price"]} ₽",
                                  image: imageUrl,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 50),

                      const Text(
                        "Разделы",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),

                      const SizedBox(height: 20),

                      _sectionButton(
                          context, Icons.local_drink, "Меню", '/menu'),
                      _sectionButton(context, Icons.map, "Карта", '/map'),
                      _sectionButton(
                          context, Icons.event, "Мероприятия", '/events'),
                      if (AppState.isAdmin)    
                      _sectionButton(
                          context, Icons.admin_panel_settings, "Админка", '/admin'),

                      const SizedBox(height: 150),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Разделы (кнопки)
  // -------------------------------------------------------------
  Widget _sectionButton(BuildContext context, IconData icon, String title, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go(route),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Карточка напитка
  // -------------------------------------------------------------
  Widget _drinkCard({
    required String name,
    required String price,
    required String? image,
  }) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8E2DE2),
            Color(0xFF4A00E0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(20)),
            child: image == null
                ? Container(
                    width: 140,
                    color: Colors.black12,
                    child: const Icon(Icons.local_drink,
                        size: 60, color: Colors.white70),
                  )
                : Image.network(
                    image,
                    width: 140,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(price,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Стеклянная карточка
  // -------------------------------------------------------------
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Размытые круги
  // -------------------------------------------------------------
  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 80,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}

// ===================================================================
//                        МЕНЮ ДЛЯ НАВИГАЦИИ
// ===================================================================
class ModernDrawer extends StatelessWidget {
  const ModernDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundImage: NetworkImage(
                "https://images.pexels.com/photos/1234/pexels-photo-1234.jpeg",
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Milk & Mocktails",
              style: TextStyle(fontSize: 22, color: Colors.white),
            ),
            const SizedBox(height: 30),

            _menuItem(context, Icons.home, "Главная", '/'),
            _menuItem(context, Icons.local_drink, "Меню", '/menu'),
            _menuItem(context, Icons.map, "Карта", '/map'),
            _menuItem(context, Icons.event, "Мероприятия", '/events'),
            if (AppState.isAdmin)
            _menuItem(context, Icons.admin_panel_settings, "Админка", '/admin'),
            _menuItem(context, Icons.lock, "Админ вход", '/admin-login'),

            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                "© 2025 Milk & Mocktails",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.cyanAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () => context.go(route),
    );
  }
}
