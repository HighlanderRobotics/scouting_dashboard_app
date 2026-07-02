import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheEntry {
  const CacheEntry({
    required this.body,
    this.etag,
    required this.timestamp,
  });

  final String body;
  final String? etag;
  final int timestamp;

  Map<String, dynamic> toJson() => {
        'body': body,
        'etag': etag,
        'ts': timestamp,
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      body: json['body'] as String,
      etag: json['etag'] as String?,
      timestamp: json['ts'] as int,
    );
  }
}

class ResponseCache {
  static const _prefsKey = 'lovat_api_cache';

  final Map<String, CacheEntry> _cache = {};

  bool _loaded = false;
  Timer? _flushTimer;
  bool _dirty = false;

  Future<void> load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);

    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          _cache[key] = CacheEntry.fromJson(value as Map<String, dynamic>);
        });
      } catch (_) {}
    }

    _loaded = true;
  }

  CacheEntry? get(String key) {
    return _cache[key];
  }

  void put(String key, String body, {String? etag}) {
    final entry = CacheEntry(
      body: body,
      etag: etag ?? _cache[key]?.etag,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _cache[key] = entry;
    _dirty = true;
    _scheduleFlush();
  }

  void remove(String key) {
    if (_cache.remove(key) != null) {
      _dirty = true;
      _scheduleFlush();
    }
  }

  void clear() {
    _cache.clear();
    _dirty = true;
    _scheduleFlush();
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(milliseconds: 500), _flush);
  }

  Future<void> _flush() async {
    if (!_dirty) return;

    _dirty = false;

    final encoded = jsonEncode(
      _cache.map((key, value) => MapEntry(key, value.toJson())),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, encoded);
  }

  Future<void> flush() async {
    await _flush();
  }
}
