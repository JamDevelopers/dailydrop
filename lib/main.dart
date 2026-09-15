import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/inquiry_provider.dart';
import 'providers/contact_provider.dart';
import 'providers/dashboard_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/navigation/main_layout.dart';
import 'features/public_catalog/public_catalog_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TextileDropApp());
}

class TextileDropApp extends StatelessWidget {
  const TextileDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => InquiryProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        title: 'TextileDrop — Surat Textile Daily Drop & Catalog SaaS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');

          // Deep linking support for Public Catalog e.g. /catalog/surat-silk-mills or /catalog/surat-silk-mills/drop/todays-drop
          if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'catalog') {
            final businessSlug = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
            final collectionSlug = uri.pathSegments.length > 3 && uri.pathSegments[2] == 'drop'
                ? uri.pathSegments[3]
                : null;
            return MaterialPageRoute(
              builder: (_) => PublicCatalogScreen(
                businessSlug: businessSlug,
                collectionSlug: collectionSlug,
              ),
            );
          }

          return MaterialPageRoute(builder: (_) => const AppRoot());
        },
        home: const AppRoot(),
      ),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    return const MainLayout();
  }
}
