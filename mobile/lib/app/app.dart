import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/albums_screen.dart';
import '../screens/gallery_screen.dart';
import '../screens/memories_screen.dart';
import '../screens/people_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/sharing_screen.dart';
import '../screens/storage_screen.dart';
import '../screens/vault_screen.dart';
import 'theme.dart';

class PhotoSyncApp extends StatelessWidget {
  const PhotoSyncApp({super.key});

  static final GoRouter router = GoRouter(
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _Shell(shell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: <RouteBase>[GoRoute(path: '/', builder: (context, state) => const GalleryScreen())]),
          StatefulShellBranch(routes: <RouteBase>[GoRoute(path: '/albums', builder: (context, state) => const AlbumsScreen())]),
          StatefulShellBranch(routes: <RouteBase>[GoRoute(path: '/search', builder: (context, state) => const SearchScreen())]),
          StatefulShellBranch(routes: <RouteBase>[GoRoute(path: '/people', builder: (context, state) => const PeopleScreen())]),
          StatefulShellBranch(routes: <RouteBase>[GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen())]),
        ],
      ),
      GoRoute(path: '/sharing', builder: (context, state) => const SharingScreen()),
      GoRoute(path: '/vault', builder: (context, state) => const VaultScreen()),
      GoRoute(path: '/storage', builder: (context, state) => const StorageScreen()),
      GoRoute(path: '/memories', builder: (context, state) => const MemoriesScreen()),
    ],
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'PhotoSync',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: router,
      );
}

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) => shell.goBranch(index),
          destinations: const <NavigationDestination>[
            NavigationDestination(icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library), label: 'Photos'),
            NavigationDestination(icon: Icon(Icons.photo_album_outlined), selectedIcon: Icon(Icons.photo_album), label: 'Albums'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
            NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'People'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      );
}
