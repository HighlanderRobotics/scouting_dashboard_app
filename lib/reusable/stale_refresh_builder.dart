import 'dart:convert';

import 'package:flutter/material.dart';

class CachedQuery<T> {
  const CachedQuery({
    required this.queryKey,
    required this.queryFn,
    this.cacheReader,
  });

  final List<dynamic> queryKey;
  final Future<T> Function() queryFn;
  final T? Function()? cacheReader;
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
}

class QueryCache {
  static final Map<String, dynamic> _memoryCache = {};

  static String _keyToString(List<dynamic> key) => jsonEncode(key);

  static T? read<T>(List<dynamic> key) {
    return _memoryCache[_keyToString(key)] as T?;
  }

  static void write<T>(List<dynamic> key, T data) {
    _memoryCache[_keyToString(key)] = data;
  }

  static void invalidate(List<dynamic> key) {
    _memoryCache.remove(_keyToString(key));
  }
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
        QueryCache.write(key, fromPersisted);
        setState(() {
          _data = fromPersisted;
        });
      }
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
        });
      }
    } catch (e) {
      if (mounted && _keyEquals(_activeKey ?? [], key)) {
        if (_data == null) {
          setState(() {
            _error = e.toString();
          });
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
