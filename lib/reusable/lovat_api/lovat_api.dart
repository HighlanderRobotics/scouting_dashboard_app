import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:scouting_dashboard_app/constants.dart';

class LovatAPI {
  LovatAPI(this.baseUrl);

  String baseUrl;
  bool _isAuthenticating = false;

  // Track if Auth0 Web SDK has been initialized
  bool _webSdkInitialized = false;
  Future<Credentials?>? _initializationFuture;

  /// Ensure the Auth0 Web SDK is initialized (must be called before any web auth operations)
  Future<Credentials?> ensureWebSdkInitialized() async {
    if (!kIsWeb) return null;
    if (_webSdkInitialized) return null;

    // Prevent concurrent initialization
    if (_initializationFuture != null) {
      return _initializationFuture;
    }

    _initializationFuture = _doInitialize();
    return _initializationFuture;
  }

  Future<Credentials?> _doInitialize() async {
    final credentials = await auth0Web.onLoad(
      audience: "https://api.lovat.app",
      scopes: {'openid', 'profile', 'email', 'offline_access'},
    );
    _webSdkInitialized = true;
    return credentials;
  }

  Future<Credentials> login() async {
    if (_isAuthenticating) {
      // Wait for the current login to finish
      while (_isAuthenticating) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (kIsWeb) {
        return await auth0Web.credentials();
      } else {
        return await auth0.credentialsManager.credentials();
      }
    }

    _isAuthenticating = true;

    try {
      if (kIsWeb) {
        await ensureWebSdkInitialized();

        final credentials = await auth0Web.loginWithPopup(
          audience: "https://api.lovat.app",
          scopes: {'openid', 'profile', 'email', 'offline_access'},
        );

        return credentials;
      } else {
        final newCredentials = await auth0
            .webAuthentication(scheme: "com.frc8033.lovatdashboard")
            .login(
          audience: "https://api.lovat.app",
          scopes: {'openid', 'profile', 'email', 'offline_access'},
        );

        await auth0.credentialsManager.storeCredentials(newCredentials);

        return newCredentials;
      }
    } finally {
      _isAuthenticating = false;
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      await ensureWebSdkInitialized();

      final hasCredentials = await auth0Web.hasValidCredentials();
      if (!hasCredentials) {
        return (await login()).accessToken;
      }

      final credentials = await auth0Web.credentials();
      return credentials.accessToken;
    }

    // Mobile/Desktop path
    try {
      final credentials = await auth0.credentialsManager.credentials();

      if (credentials.expiresAt.isBefore(DateTime.now())) {
        if (credentials.refreshToken == null) {
          return (await login()).accessToken;
        }

        final newCredentials = await auth0.api
            .renewCredentials(refreshToken: credentials.refreshToken!);

        await auth0.credentialsManager.storeCredentials(newCredentials);

        return newCredentials.accessToken;
      } else {
        return credentials.accessToken;
      }
    } on CredentialsManagerException {
      return (await login()).accessToken;
    }
  }

  Future<http.Response?> get(String path, {Map<String, String>? query}) async {
    final token = await getAccessToken();

    final uri = Uri.parse(baseUrl + path).replace(queryParameters: query);

    return await http.get(uri, headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  Future<http.Response?> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final token = await getAccessToken();

    final uri = Uri.parse(baseUrl + path).replace(queryParameters: query);

    return await http
        .post(uri, body: body != null ? jsonEncode(body) : null, headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  Future<http.Response?> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final token = await getAccessToken();

    final uri = Uri.parse(baseUrl + path).replace(queryParameters: query);

    return await http
        .put(uri, body: body != null ? jsonEncode(body) : null, headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  Future<http.Response?> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final token = await getAccessToken();

    final uri = Uri.parse(baseUrl + path).replace(queryParameters: query);

    return await http
        .delete(uri, body: body != null ? jsonEncode(body) : null, headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }
}

class LovatAPIException implements Exception {
  const LovatAPIException(this.message);

  final String message;

  @override
  String toString() => message;
}

const kProductionBaseUrl = "https://lovat-server-staging.up.railway.app";

final lovatAPI = LovatAPI(kProductionBaseUrl);
