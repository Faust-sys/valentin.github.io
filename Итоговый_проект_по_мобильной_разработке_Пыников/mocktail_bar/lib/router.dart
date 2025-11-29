import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/home_page.dart';
import 'pages/menu_page.dart';
import 'pages/map_page.dart';
import 'pages/events_page.dart';
import 'pages/admin_page.dart';
import 'pages/admin_login_page.dart';   // ✅ добавляем импорт

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) =>
          const HomePage(),
    ),
    GoRoute(
      path: '/menu',
      name: 'menu',
      builder: (BuildContext context, GoRouterState state) =>
          const MenuPage(),
    ),
    GoRoute(
      path: '/map',
      name: 'map',
      builder: (BuildContext context, GoRouterState state) =>
          const MapPage(),
    ),
    GoRoute(
      path: '/events',
      name: 'events',
      builder: (BuildContext context, GoRouterState state) =>
          const EventsPage(),
    ),

    // ✅ Страница логина админа
    GoRoute(
      path: '/admin-login',
      name: 'admin-login',
      builder: (BuildContext context, GoRouterState state) =>
          const AdminLoginPage(),
    ),

    // ❗ Доступна только после авторизации
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (BuildContext context, GoRouterState state) =>
          const AdminPage(),
    ),
  ],
);
