import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/app_state.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AdminAuthService {
  static Future<bool> login(String username, String password) async {
    // получаем данные юзера
    final response = await Supabase.instance.client
        .from('admin_users')
        .select()
        .eq("username", username)
        .maybeSingle();

    if (response == null) return false;

    final storedHash = response["password_hash"];

    // bcrypt-проверка
    final verify = await Supabase.instance.client.rpc(
      'check_password',
      params: {
        'password': password,
        'hash': storedHash,
      },
    );

    if (verify == true) {
      AppState.isAdmin = true;
      return true;
    }

    return false;
  }

  static void logout() {
    AppState.isAdmin = false;
  }
}
