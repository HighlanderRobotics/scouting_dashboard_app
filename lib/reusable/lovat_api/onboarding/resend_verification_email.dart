import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension ResendVerificationEmail on LovatAPI {
  Future<void> resendVerificationEmail() async {
    final response =
        await post('/v1/manager/onboarding/resendverificationemail');

    if (response?.statusCode == 200) return;

    if (response?.statusCode == 429) {
      throw const LovatAPIException(
          'Too many emails. Please wait a few minutes.');
    }

    debugPrint(response?.body ?? '');
    throw const LovatAPIException('Failed to resend verification email');
  }
}
