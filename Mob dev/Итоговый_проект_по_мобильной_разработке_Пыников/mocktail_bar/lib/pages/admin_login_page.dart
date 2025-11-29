import 'package:flutter/material.dart';
import '../services/admin_auth_service.dart';
import '../pages/app_state.dart';
import 'package:go_router/go_router.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final loginC = TextEditingController();
  final passC = TextEditingController();
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Вход администратора"),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3F2B96), Color(0xFF64DFDF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Center(
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Админ панель",
                      style: TextStyle(fontSize: 26, color: Colors.white)),
                  const SizedBox(height: 20),

                  TextField(
                    controller: loginC,
                    decoration: const InputDecoration(
                      labelText: "Логин",
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: passC,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Пароль",
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),

                  const SizedBox(height: 20),

                  if (error != null)
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),

                  const SizedBox(height: 15),

                  ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            setState(() {
                              loading = true;
                              error = null;
                            });

                            final ok = await AdminAuthService.login(
                                loginC.text.trim(), passC.text.trim());

                            if (ok) {
                              context.go("/admin");
                            } else {
                              setState(() {
                                error = "Неверный логин или пароль";
                              });
                            }

                            setState(() => loading = false);
                          },
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Войти"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
