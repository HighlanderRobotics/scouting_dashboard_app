import 'dart:convert';

import 'package:flutter/material.dart';

class CachedQuery<T> {
  const CachedQuery({
    required this.queryKey,
    required this.queryFn,
    required this.label,
    this.cacheReader,
    this.cacheTimestampReader,
  });

  final List<dynamic> queryKey;
  final Future<T> Function() queryFn;
  final String label;
  final T? Function()? cacheReader;
  final DateTime? Function()? cacheTimestampReader;
}

class QueryResult<T> {
  const QueryResult({
    this.data,
    this.error,
    this.isFetching = false,
    required this.refetch,
  });

  final T? data;
  final String? error;
  final bool isFetching;
  final VoidCallback refetch;

  bool get hasData => data != null;
  bool get hasError => error != null;
  bool get isStale => data != null && error != null;
}

class QueryCache {
  static final Map<String, _CacheEntry> _memoryCache = {};

  static String _keyToString(List<dynamic> key) => jsonEncode(key);

  static T? read<T>(List<dynamic> key) {
    return _memoryCache[_keyToString(key)]?.data as T?;
  }

  static DateTime? readTimestamp(List<dynamic> key) {
    return _memoryCache[_keyToString(key)]?.timestamp;
  }

  static void write<T>(List<dynamic> key, T data, {DateTime? timestamp}) {
    _memoryCache[_keyToString(key)] =
        _CacheEntry(data, timestamp ?? DateTime.now());
  }

  static void invalidate(List<dynamic> key) {
    _memoryCache.remove(_keyToString(key));
  }

  static void clearAll() {
    _memoryCache.clear();
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  _CacheEntry(this.data, this.timestamp);
}

class StaleRefreshBuilder<T> extends StatefulWidget {
  const StaleRefreshBuilder({
    super.key,
    required this.query,
    required this.builder,
  });

  final CachedQuery<T> query;
  final Widget Function(BuildContext context, QueryResult<T> result) builder;

  @override
  State<StaleRefreshBuilder<T>> createState() => _StaleRefreshBuilderState<T>();
}

class _StaleRefreshBuilderState<T> extends State<StaleRefreshBuilder<T>> {
  T? _data;
  String? _error;
  bool _isFetching = false;
  List<dynamic>? _activeKey;
  DateTime? _cacheTimestamp;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(StaleRefreshBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_keyEquals(widget.query.queryKey, oldWidget.query.queryKey)) {
      setState(() {
        _data = null;
        _error = null;
      });
      _fetch();
    }
  }

  bool _keyEquals(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _fetch() async {
    final key = widget.query.queryKey;
    _activeKey = key;

    final fromMemory = QueryCache.read<T>(key);
    if (fromMemory != null && _data == null && _error == null && mounted) {
      setState(() {
        _data = fromMemory;
      });
    } else if (fromMemory == null &&
        _data == null &&
        _error == null &&
        widget.query.cacheReader != null) {
      final fromPersisted = widget.query.cacheReader!();
      if (fromPersisted != null && mounted) {
        final persistedTimestamp = widget.query.cacheTimestampReader?.call();
        QueryCache.write(key, fromPersisted, timestamp: persistedTimestamp);
        setState(() {
          _data = fromPersisted;
        });
      }
    }

    if (_cacheTimestamp == null) {
      _cacheTimestamp = QueryCache.readTimestamp(key);
    }

    if (mounted) {
      setState(() {
        _isFetching = true;
      });
    }

    try {
      final result = await widget.query.queryFn();
      if (mounted && _keyEquals(_activeKey ?? [], key)) {
        QueryCache.write(key, result);
        setState(() {
          _data = result;
          _error = null;
          _cacheTimestamp = QueryCache.readTimestamp(key);
        });
      }
    } catch (e) {
      if (mounted && _keyEquals(_activeKey ?? [], key)) {
        setState(() {
          _error = e.toString();
        });
        if (_data != null) {
          _showStaleErrorSnackBar();
        }
      }
    } finally {
      if (mounted && _keyEquals(_activeKey ?? [], key)) {
        setState(() {
          _isFetching = false;
        });
      }
    }
  }

  void _refetch() {
    if (!mounted) return;
    setState(() {
      _error = null;
    });
    _fetch();
  }

  void _showStaleErrorSnackBar() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final subtitle = _cacheTimestamp != null
        ? Text(
            "Showing data from ${_formatRelativeTime(DateTime.now().difference(_cacheTimestamp!))}",
          )
        : null;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Failed to get ${widget.query.label}."),
              if (subtitle != null) subtitle,
            ],
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "Retry",
            onPressed: _refetch,
          ),
        ),
      );
  }

  static String _formatRelativeTime(Duration duration) {
    if (duration.inMinutes < 1) return "just now";
    if (duration.inHours < 1) {
      final m = duration.inMinutes;
      return "$m minute${m == 1 ? '' : 's'} ago";
    }
    if (duration.inDays < 1) {
      final h = duration.inHours;
      return "$h hour${h == 1 ? '' : 's'} ago";
    }
    final d = duration.inDays;
    return "$d day${d == 1 ? '' : 's'} ago";
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      QueryResult<T>(
        data: _data,
        error: _error,
        isFetching: _isFetching,
        refetch: _refetch,
      ),
    );
  }
}
