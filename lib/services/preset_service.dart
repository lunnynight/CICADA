import 'dart:convert';
import 'package:flutter/services.dart';

class PresetService {
  static Future<Map<String, dynamic>> loadCnModels() async {
    final str = await rootBundle.loadString('assets/presets/models-cn.json');
    return json.decode(str);
  }

  static Future<Map<String, dynamic>> loadIntlModels() async {
    final str = await rootBundle.loadString('assets/presets/models-intl.json');
    return json.decode(str);
  }

  static Future<Map<String, dynamic>> loadMirrors() async {
    final str = await rootBundle.loadString('assets/presets/mirrors.json');
    return json.decode(str);
  }
}
