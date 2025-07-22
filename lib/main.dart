import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart' as theme_provider;
import 'screens/splash_screen.dart';
import 'package:flutter/material.dart' show ThemeMode;

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(theme_provider.themeProvider);
    
    return MaterialApp(
      title: 'RDV Manager',
      debugShowCheckedModeBanner: false,
      theme: theme_provider.AppThemes.lightTheme,
      darkTheme: theme_provider.AppThemes.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}