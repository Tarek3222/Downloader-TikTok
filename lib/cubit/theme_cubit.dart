import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreset {
  final String name;
  final Color accentColor;
  final Color? secondaryColor;
  final IconData icon;

  const ThemePreset({
    required this.name,
    required this.accentColor,
    this.secondaryColor,
    required this.icon,
  });
}

class ThemeState extends Equatable {
  final ThemeMode themeMode;
  final int currentPresetIndex;
  final List<ThemePreset> presets;

  const ThemeState({
    required this.themeMode,
    required this.currentPresetIndex,
    required this.presets,
  });

  Color get accentColor => presets[currentPresetIndex].accentColor;

  ThemeState copyWith({
    ThemeMode? themeMode,
    int? currentPresetIndex,
    List<ThemePreset>? presets,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      currentPresetIndex: currentPresetIndex ?? this.currentPresetIndex,
      presets: presets ?? this.presets,
    );
  }

  @override
  List<Object?> get props => [themeMode, currentPresetIndex];
}

class ThemeCubit extends Cubit<ThemeState> {
  static const _themeKey = 'theme_mode';
  static const _presetIndexKey = 'preset_index';

  // Cache SharedPreferences instance to avoid repeated allocations and I/O
  final Future<SharedPreferences> _prefsFuture =
      SharedPreferences.getInstance();

  ThemeCubit()
      : super(
          const ThemeState(
            themeMode: ThemeMode.system,
            currentPresetIndex: 0,
            presets: [
              ThemePreset(
                name: 'TikTok Pink',
                accentColor: Color(0xFFFF2C55),
                icon: Icons.favorite_rounded,
              ),
              ThemePreset(
                name: 'Ocean Blue',
                accentColor: Color(0xFF00B4D8),
                icon: Icons.water_rounded,
              ),
              ThemePreset(
                name: 'Emerald',
                accentColor: Color(0xFF2ECC71),
                icon: Icons.eco_rounded,
              ),
              ThemePreset(
                name: 'Royal Purple',
                accentColor: Color(0xFF9B59B6),
                icon: Icons.auto_awesome_rounded,
              ),
              ThemePreset(
                name: 'Sunset Orange',
                accentColor: Color(0xFFE67E22),
                icon: Icons.wb_sunny_rounded,
              ),
              ThemePreset(
                name: 'Neon',
                accentColor: Color(0xFF39FF14),
                icon: Icons.bolt_rounded,
              ),
              ThemePreset(
                name: 'Cherry Red',
                accentColor: Color(0xFFE74C3C),
                icon: Icons.local_florist_rounded,
              ),
              ThemePreset(
                name: 'Deep Purple',
                accentColor: Color(0xFF6C3483),
                icon: Icons.nights_stay_rounded,
              ),
            ],
          ),
        ) {
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final prefs = await _prefsFuture;
    final savedPresetIndex = prefs.getInt(_presetIndexKey);
    final savedThemeModeIndex = prefs.getInt(_themeKey);

    var newState = state;
    if (savedPresetIndex != null &&
        savedPresetIndex >= 0 &&
        savedPresetIndex < state.presets.length) {
      newState = newState.copyWith(currentPresetIndex: savedPresetIndex);
    }
    if (savedThemeModeIndex != null &&
        savedThemeModeIndex >= 0 &&
        savedThemeModeIndex < ThemeMode.values.length) {
      newState =
          newState.copyWith(themeMode: ThemeMode.values[savedThemeModeIndex]);
    }
    // Avoid emitting identical state to prevent unnecessary rebuilds
    if (newState != state) {
      emit(newState);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state.themeMode == mode) return;
    emit(state.copyWith(themeMode: mode));
    final prefs = await _prefsFuture;
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> cycleThemeMode() async {
    const modes = ThemeMode.values;
    final currentIndex = modes.indexOf(state.themeMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    await setThemeMode(modes[nextIndex]);
  }

  /// Toggle strictly between light and dark, ignoring system mode.
  Future<void> toggleLightDark() async {
    final next =
        state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  Future<void> setPreset(int index) async {
    if (index < 0 || index >= state.presets.length) return;
    if (index == state.currentPresetIndex) return;
    emit(state.copyWith(currentPresetIndex: index));
    final prefs = await _prefsFuture;
    await prefs.setInt(_presetIndexKey, index);
  }

  Future<void> nextPreset() =>
      setPreset((state.currentPresetIndex + 1) % state.presets.length);
  Future<void> previousPreset() =>
      setPreset((state.currentPresetIndex - 1 + state.presets.length) %
          state.presets.length);
}
