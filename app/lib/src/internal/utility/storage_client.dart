import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'alloy_key.dart';

class StorageClient {

  late final RxSharedPreferences _prefs;

  Future<void> init() async {
    _prefs = RxSharedPreferences(
      await SharedPreferences.getInstance(),
      null,
      // kReleaseMode ? null : RxSharedPreferencesDefaultLogger(),
    );
  }

  Stream<String> getString(AlloyKey key, {required String defaultValue}) {
    return _prefs.getStringStream(key.value).map((value) => value ?? defaultValue).share();
  }

  Stream<bool> getBool(AlloyKey key, {required bool defaultValue}) {
    return _prefs.getBoolStream(key.value).map((value) => value ?? defaultValue);
  }

  Stream<int> getInt(AlloyKey key, {required int defaultValue}) {
    return _prefs.getIntStream(key.value).map((value) => value ?? defaultValue);
  }

  Stream<double> getDouble(AlloyKey key, {required double defaultValue}) {
    return _prefs.getDoubleStream(key.value).map((value) => value ?? defaultValue);
  }

  Stream<List<String>> getStringList(AlloyKey key, {required List<String> defaultValue}) {
    return _prefs.getStringListStream(key.value).map((value) => value ?? defaultValue);
  }

  Future<void> setString(AlloyKey key, String value) => _prefs.setString(key.value, value);
  Future<void> setBool(AlloyKey key, bool value) => _prefs.setBool(key.value, value);
  Future<void> setInt(AlloyKey key, int value) => _prefs.setInt(key.value, value);
  Future<void> setDouble(AlloyKey key, double value) => _prefs.setDouble(key.value, value);
  Future<void> setStringList(AlloyKey key, List<String> value) => _prefs.setStringList(key.value, value);

  Future<void> remove(AlloyKey key) async {
    await _prefs.remove(key.value);
  }
}
