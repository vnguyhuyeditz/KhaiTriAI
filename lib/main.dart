import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/audio_service.dart';
import 'audio/sound_navigator_observer.dart';
import 'notifications/reminder_service.dart';
import 'settings/settings_controller.dart';
import 'ui/home_screen.dart';
import 'ui/intro_screen.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsController.load();
  await AudioService.instance.init(settings);
  await ReminderService.instance.init();
  runApp(KhaiTriApp(settings: settings));
}

class KhaiTriApp extends StatelessWidget {
  final SettingsController settings;
  const KhaiTriApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      controller: settings,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return MaterialApp(
            title: 'Khai Trí AI',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: AppTheme.build(Brightness.light, settings.font),
            darkTheme: AppTheme.build(Brightness.dark, settings.font),
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              final dark = Theme.of(context).brightness == Brightness.dark;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness:
                      dark ? Brightness.light : Brightness.dark,
                  statusBarBrightness: dark ? Brightness.dark : Brightness.light,
                ),
                // Nhân cỡ chữ người dùng chọn với cỡ chữ của hệ thống.
                child: MediaQuery(
                  data: mq.copyWith(
                    textScaler: TextScaler.linear(
                      mq.textScaler.scale(1) * settings.textScale,
                    ),
                  ),
                  child: child!,
                ),
              );
            },
            navigatorObservers: [SoundNavigatorObserver()],
            home: const IntroGate(home: HomeScreen()),
          );
        },
      ),
    );
  }
}
