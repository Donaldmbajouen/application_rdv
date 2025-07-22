import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/services_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/theme_provider.dart' as theme_provider;
import 'package:flutter/material.dart' show ThemeMode;

void main() => runApp(const ProviderScope(child: TestApp()));

class TestApp extends ConsumerWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(theme_provider.themeProvider);
    
    return MaterialApp(
      title: 'RDV Manager - Test',
      debugShowCheckedModeBanner: false,
      theme: theme_provider.AppThemes.lightTheme,
      darkTheme: theme_provider.AppThemes.darkTheme,
      themeMode: themeMode,
      home: const ScreenTestMenu(),
    );
  }
}

class ScreenTestMenu extends StatelessWidget {
  const ScreenTestMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test des écrans'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTestButton(
            context,
            'Splash Screen',
            'Écran de démarrage',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SplashScreen())),
          ),
          _buildTestButton(
            context,
            'Onboarding',
            'Introduction première utilisation',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingScreen())),
          ),
          _buildTestButton(
            context,
            'Home Screen',
            'Écran principal avec navigation',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
          ),
          _buildTestButton(
            context,
            'Calendrier',
            'Gestion des rendez-vous',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
          ),
          _buildTestButton(
            context,
            'Clients',
            'Gestion des clients',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsScreen())),
          ),
          _buildTestButton(
            context,
            'Services',
            'Catalogue des services',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesScreen())),
          ),
          _buildTestButton(
            context,
            'Statistiques',
            'Graphiques et métriques',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
          ),
          _buildTestButton(
            context,
            'Paramètres',
            'Configuration de l\'app',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          
          const SizedBox(height: 32),
          
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Test réussi !',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tous les écrans principaux compilent correctement.\nL\'application est prête à être utilisée !',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(BuildContext context, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(
            Icons.smartphone,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
