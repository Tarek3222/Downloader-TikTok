// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_file/open_file.dart';
import '../cubit/download_cubit.dart';
import '../cubit/theme_cubit.dart';
import '../cubit/language_cubit.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _openDownloadsFolder(BuildContext context) async {
    try {
      final path = await context.read<DownloadCubit>().getDownloadPath();
      if (path != null) {
        if (Platform.isWindows) {
          await Process.run('explorer', [path]);
        } else {
          await OpenFile.open(path);
        }
      } else {
        Get.snackbar(
          'error'.tr,
          'download_path_not_set'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'could_not_open_folder'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(builder: (context, themeState) {
      final languageCubit = context.read<LanguageCubit>();
      return BlocBuilder<LanguageCubit, LanguageState>(builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('settings'.tr),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'theme_mode'.tr,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: themeState.accentColor,
                      fontSize: 20,
                    ),
                  ),
                ),
                subtitle: Text(
                  themeState.themeMode.name,
                  style: context.textTheme.bodySmall,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'system'.tr,
                      icon: Icon(
                        Icons.phone_iphone,
                        color: themeState.themeMode == ThemeMode.system
                            ? themeState.accentColor
                            : themeState.accentColor.withOpacity(0.4),
                      ),
                      onPressed: () => context
                          .read<ThemeCubit>()
                          .setThemeMode(ThemeMode.system),
                    ),
                    IconButton(
                      tooltip: 'light'.tr,
                      icon: Icon(
                        Icons.light_mode,
                        color: themeState.themeMode == ThemeMode.light
                            ? themeState.accentColor
                            : themeState.accentColor.withOpacity(0.4),
                      ),
                      onPressed: () => context
                          .read<ThemeCubit>()
                          .setThemeMode(ThemeMode.light),
                    ),
                    IconButton(
                      tooltip: 'dark'.tr,
                      icon: Icon(
                        Icons.dark_mode,
                        color: themeState.themeMode == ThemeMode.dark
                            ? themeState.accentColor
                            : themeState.accentColor.withOpacity(0.4),
                      ),
                      onPressed: () => context
                          .read<ThemeCubit>()
                          .setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'color_themes'.tr,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: themeState.accentColor,
                  ),
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: themeState.presets.length,
                  itemBuilder: (context, index) {
                    final preset = themeState.presets[index];
                    final isSelected = index == themeState.currentPresetIndex;
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () =>
                            context.read<ThemeCubit>().setPreset(index),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            color: preset.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? preset.accentColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                preset.icon,
                                color: preset.accentColor,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                preset.name,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: preset.accentColor,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  'language'.tr,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: themeState.accentColor,
                  ),
                ),
                trailing: TextButton.icon(
                  onPressed: () => languageCubit.toggleLanguage(),
                  icon: Icon(
                    Icons.language,
                    color: themeState.accentColor,
                  ),
                  label: BlocBuilder<LanguageCubit, LanguageState>(
                    builder: (context, state) {
                      return Text(
                        languageCubit.state.currentLanguage,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: themeState.accentColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Divider(),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.folder,
                    color: themeState.accentColor,
                  ),
                  title: Text(
                    'downloads_folder'.tr,
                    style: context.textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    'open_downloads'.tr,
                    style: context.textTheme.bodyMedium,
                  ),
                  onTap: () => _openDownloadsFolder(context),
                ),
              ).animate().fadeIn().slideX(),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.info,
                    color: themeState.accentColor,
                  ),
                  title: Text(
                    'about'.tr,
                    style: context.textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    'version'.tr,
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ).animate().fadeIn().slideX(delay: 100.ms),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.person,
                    color: themeState.accentColor,
                  ),
                  title: Text(
                    'developer'.tr,
                    style: context.textTheme.bodyLarge,
                  ),
                  subtitle: const Text(
                    'Tarek Ahmed',
                    style: TextStyle(fontFamily: 'Inter'),
                  ),
                  onTap: () {},
                ),
              ).animate().fadeIn().slideX(delay: 200.ms),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.code,
                    color: themeState.accentColor,
                  ),
                  title: Text(
                    'source_code'.tr,
                    style: context.textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    'view_github'.tr,
                    style: context.textTheme.bodyMedium,
                  ),
                  onTap: () => launchUrlString(
                    'https://github.com/imcr1',
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ).animate().fadeIn().slideX(delay: 300.ms),
            ],
          ),
        );
      });
    });
  }
}
