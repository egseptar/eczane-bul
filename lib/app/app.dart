import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/services/preference_service.dart';
import '../features/home/screens/home_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Eczane Bul',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: FutureBuilder<bool>(
            future: PreferenceService.instance.isFirstLaunch(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: Theme.of(context).colorScheme.background,
                  body: const SizedBox.shrink(),
                );
              }
              final isFirstLaunch = snapshot.data ?? true;
              return isFirstLaunch ? const OnboardingScreen() : const HomeScreen();
            },
          ),
        );
      },
    );
  }
}
