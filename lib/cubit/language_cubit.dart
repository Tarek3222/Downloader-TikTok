import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageState extends Equatable {
  final Locale locale;

  const LanguageState(this.locale);

  bool get isRTL => locale.languageCode == 'ar';
  String get currentLanguage =>
      locale.languageCode == 'ar' ? 'العربية' : 'English';

  @override
  List<Object?> get props => [locale];
}

class LanguageCubit extends Cubit<LanguageState> {
  static const _languageKey = 'language_code';
  static const _countryKey = 'country_code';
  final _locale = const Locale('en', 'US').obs;

  final List<Map<String, String>> languages = const [
    {'name': 'English', 'code': 'en', 'country': 'US'},
    {'name': 'العربية', 'code': 'ar', 'country': 'SA'},
  ];

  LanguageCubit() : super(const LanguageState(Locale('en', 'US'))) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    final countryCode = prefs.getString(_countryKey);
    if (languageCode != null) {
      final newLocale = Locale(languageCode, countryCode);
      _locale.value = newLocale;
      emit(LanguageState(newLocale));
      Get.updateLocale(newLocale);
    }
  }

  Future<void> changeLanguage(String languageCode, String countryCode) async {
    final local = Locale(languageCode, countryCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    await prefs.setString(_countryKey, countryCode);
    _locale.value = local;
    emit(LanguageState(local));
    Get.updateLocale(local);
  }

  Future<void> toggleLanguage() async {
    if (state.locale.languageCode == 'en') {
      await changeLanguage('ar', 'SA');
    } else {
      await changeLanguage('en', 'US');
    }
  }

  Locale get locale => _locale.value;
  String get currentLanguage =>
      _locale.value.languageCode == 'ar' ? 'العربية' : 'English';
  String get currentCountry => _locale.value.countryCode == 'SA'
      ? 'المملكة العربية السعودية'
      : 'United States';
  bool get isRTL => _locale.value.languageCode == 'ar';
}
