import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ⚠️ импортируем панель навигации
import 'home_page.dart'; // <-- путь поправь под свой проект

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  Future<List<Map<String, dynamic>>> loadDrinks() async {
    final res = await Supabase.instance.client
        .from('drinks')
        .select()
        .order('id', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null) return;

    setState(() {
      _selectedImageBytes = result.files.first.bytes!;
      _selectedImageName = result.files.first.name;
    });
  }

  Future<String?> uploadImage(Uint8List bytes, String filename) async {
    try {
      final path =
          "drink_${DateTime.now().millisecondsSinceEpoch}_$filename";

      await Supabase.instance.client.storage
          .from("drinks")
          .uploadBinary(path, bytes);

      return path;
    } catch (e) {
      print("Ошибка загрузки изображения: $e");
      return null;
    }
  }

  Future<void> addDrinkDialog() async {
    final nameC = TextEditingController();
    final catC = TextEditingController();
    final priceC = TextEditingController();

    _selectedImageBytes = null;
    _selectedImageName = null;

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: _glassCard(
          padding: 20,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "Добавить напиток",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),

                _inputField("Название", nameC),
                _inputField("Категория", catC),
                _inputField("Цена", priceC, number: true),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text("Выбрать изображение"),
                  style: _btnStyle(),
                ),

                if (_selectedImageBytes != null) ...[
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(_selectedImageBytes!, height: 160),
                  ),
                ],

                const SizedBox(height: 25),

                ElevatedButton(
                  onPressed: () async {
                    String? imgPath;

                    if (_selectedImageBytes != null &&
                        _selectedImageName != null) {
                      imgPath = await uploadImage(
                        _selectedImageBytes!,
                        _selectedImageName!,
                      );
                    }

                    await Supabase.instance.client.from("drinks").insert({
                      "name": nameC.text,
                      "category": catC.text,
                      "price": double.tryParse(priceC.text) ?? 0,
                      "image_path": imgPath,
                    });

                    if (context.mounted) Navigator.pop(context);
                    setState(() {});
                  },
                  style: _btnStyle(),
                  child: const Text("Добавить"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> deleteDrink(int id) async {
    await Supabase.instance.client
        .from("drinks")
        .delete()
        .match({"id": id});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      // 🔥 ДОБАВЛЯЕМ БОКОВОЕ МЕНЮ
      drawer: const ModernDrawer(),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: addDrinkDialog,
        icon: const Icon(Icons.add),
        label: const Text("Добавить"),
        backgroundColor: Colors.deepPurpleAccent,
      ),

      appBar: AppBar(
        title: const Text("Админка / Напитки"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Stack(
        children: [
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

          SafeArea(
            child: FutureBuilder(
              future: loadDrinks(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final drinks = snapshot.data!;
                if (drinks.isEmpty) {
                  return const Center(
                    child: Text(
                      "Пока нет напитков",
                      style: TextStyle(color: Colors.white70, fontSize: 20),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 900 ? 3 : 1,
                      childAspectRatio: 1,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: drinks.length,
                    itemBuilder: (_, i) {
                      final d = drinks[i];
                      final img = d['image_path'];

                      final url = img == null
                          ? null
                          : Supabase.instance.client.storage
                              .from("drinks")
                              .getPublicUrl(img);

                      return _drinkAdminCard(
                        name: d["name"],
                        price: d["price"].toString(),
                        category: d["category"],
                        imageUrl: url,
                        onDelete: () => deleteDrink(d["id"]),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Карточки, UI элементы остаются теми же ---
  // (оставил без изменений)
  Widget _drinkAdminCard({
    required String name,
    required String price,
    required String category,
    required String? imageUrl,
    required VoidCallback onDelete,
  }) {
    return _glassCard(
      padding: 0,
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: imageUrl == null
                  ? Container(
                      color: Colors.black26,
                      child: const Center(
                        child:
                            Icon(Icons.local_drink, size: 70, color: Colors.white70),
                      ),
                    )
                  : Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  "$price ₽",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      label: const Text("Удалить",
                          style: TextStyle(color: Colors.redAccent)),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child, double padding = 16}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl,
      {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder:
              const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        ),
      ),
    );
  }

  ButtonStyle _btnStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white.withOpacity(0.2),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
