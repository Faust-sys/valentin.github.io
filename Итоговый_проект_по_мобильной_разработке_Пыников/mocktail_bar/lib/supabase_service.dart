import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // SELECT
  Future<List<Map<String, dynamic>>> getDrinks() async {
    final result = await _client
        .from('drinks')
        .select()
        .order('created_at');
    return List<Map<String, dynamic>>.from(result);
  }

  // INSERT
  Future<void> addDrink({
    required String name,
    required String category,
    required double price,
    String? imageUrl,
    bool isSpecial = false,
  }) async {
    await _client.from('drinks').insert({
      'name': name,
      'category': category,
      'price': price,
      'image_url': imageUrl,
      'is_special': isSpecial,
    });
  }

  // UPDATE
  Future<void> updateDrink(
    int id, {
    String? name,
    String? category,
    double? price,
    String? imageUrl,
    bool? isSpecial,
  }) async {
    final Map<String, dynamic> data = {};

    if (name != null) data['name'] = name;
    if (category != null) data['category'] = category;
    if (price != null) data['price'] = price;
    if (imageUrl != null) data['image_url'] = imageUrl;
    if (isSpecial != null) data['is_special'] = isSpecial;

    if (data.isNotEmpty) {
      await _client.from('drinks').update(data).eq('id', id);
    }
  }

  // DELETE
  Future<void> deleteDrink(int id) async {
    await _client.from('drinks').delete().eq('id', id);
  }
}
