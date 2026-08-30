import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Framework-level fallbacks for Standard Moroccan Tamazight.
///
/// Flutter does not currently ship Material, Cupertino, or Widgets
/// localizations for `zgh`. The app strings still come from AppLocalizations;
/// these delegates keep framework widgets usable and establish Tifinagh's LTR
/// direction until Flutter provides native `zgh` localizations.
abstract final class ZghFrameworkLocalizations {
  static const delegates = <LocalizationsDelegate<dynamic>>[
    _ZghMaterialLocalizationsDelegate(),
    _ZghCupertinoLocalizationsDelegate(),
    _ZghWidgetsLocalizationsDelegate(),
  ];
}

bool _isZgh(Locale locale) => locale.languageCode == 'zgh';

class _ZghMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _ZghMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isZgh(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultMaterialLocalizations());

  @override
  bool shouldReload(_ZghMaterialLocalizationsDelegate old) => false;
}

class _ZghCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _ZghCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isZgh(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultCupertinoLocalizations());

  @override
  bool shouldReload(_ZghCupertinoLocalizationsDelegate old) => false;
}

class _ZghWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _ZghWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isZgh(locale);

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultWidgetsLocalizations());

  @override
  bool shouldReload(_ZghWidgetsLocalizationsDelegate old) => false;
}
