import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/xebo_models.dart';

const _storageKey = 'com.xebo.offline_responses';

class XeboOfflineQueue {
  static Future<void> enqueue(XeboQueuedResponse response) async {
    final all = await getAll();
    all.add(response);
    await saveAll(all);
    debugQueueLog('[Xebo Offline Queue] Enqueued: ${response.responseId}');
  }

  static Future<List<XeboQueuedResponse>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => XeboQueuedResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<XeboQueuedResponse> responses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(responses.map((r) => r.toJson()).toList()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

void debugQueueLog(String message) {
  // ignore: avoid_print
  print(message);
}
