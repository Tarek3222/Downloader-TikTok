// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'cubit/theme_cubit.dart';
import 'cubit/language_cubit.dart';
import 'translations/app_translations.dart';
import 'views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Avoid delaying first frame; request permissions in background
  // Fonts: prevent runtime HTTP fetching to reduce jank and memory
  // GoogleFonts.config.allowRuntimeFetching = false;
  await _requestPermissions();

  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  if (Platform.isAndroid) {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    if (deviceInfo.version.sdkInt <= 32) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    } else {
      final photosStatus = await Permission.photos.status;
      if (!photosStatus.isGranted) {
        await Permission.photos.request();
      }
      final videosStatus = await Permission.videos.status;
      if (!videosStatus.isGranted) {
        await Permission.videos.request();
      }
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => LanguageCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        buildWhen: (previous, current) =>
            previous.themeMode != current.themeMode ||
            previous.accentColor != current.accentColor,
        builder: (context, themeState) {
          return BlocBuilder<LanguageCubit, LanguageState>(
            buildWhen: (previous, current) => previous.locale != current.locale,
            builder: (context, langState) => GetMaterialApp(
              title: 'TikTok Downloader',
              debugShowCheckedModeBanner: false,
              theme: _buildTheme(Brightness.light, themeState.accentColor),
              darkTheme: _buildTheme(Brightness.dark, themeState.accentColor),
              themeMode: themeState.themeMode,
              translations: AppTranslations(),
              locale: langState.locale,
              fallbackLocale: const Locale('en', 'US'),
              home: const SplashView(),
            ),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness, Color accentColor) {
    return _ThemeCache.instance.get(brightness, accentColor, () {
      final isDark = brightness == Brightness.dark;
      final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();

      return baseTheme.copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: brightness,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: isDark ? Colors.black : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.vt323(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: GoogleFonts.vt323(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
          titleLarge: GoogleFonts.vt323(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          titleMedium: GoogleFonts.vt323(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          titleSmall: GoogleFonts.vt323(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      );
    });
  }
}

class _ThemeCache {
  _ThemeCache._();
  static final _ThemeCache instance = _ThemeCache._();

  // Small LRU cache to prevent unbounded growth
  static const int _maxEntries = 8;
  final LinkedHashMap<int, ThemeData> _cache = LinkedHashMap<int, ThemeData>();

  ThemeData get(
      Brightness brightness, Color accent, ThemeData Function() build) {
    final key = _makeKey(brightness, accent);
    final existing = _cache.remove(key);
    if (existing != null) {
      // Re-insert to mark as most-recently used
      _cache[key] = existing;
      return existing;
    }
    final theme = build();
    _cache[key] = theme;
    if (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    return theme;
  }

  int _makeKey(Brightness brightness, Color accent) {
    final b = brightness == Brightness.dark ? 1 : 0;
    return (b << 31) ^ accent.value;
  }
}
