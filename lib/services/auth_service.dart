import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> sendOtp(String phoneNumber) async {
    try {
      final response = await _supabase.functions.invoke(
        'auth-otp',
        body: {'phone': phoneNumber},
      );

      if (response.status != 200) {
        final data = response.data;
        if (data is Map && data['error'] != null) {
          throw Exception(data['error'].toString());
        }
        throw Exception('Failed to send OTP');
      }

      debugPrint('OTP sent successfully to $phoneNumber');
    } catch (error) {
      debugPrint('OTP send error: $error');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'auth-otp-verify',
        body: {'phone': phone, 'token': otp},
      );

      if (response.data is! Map) {
        throw Exception('Invalid response received from server');
      }

      final data = Map<String, dynamic>.from(response.data as Map);

      if (response.status != 200) {
        if (data['error'] != null) {
          throw Exception(data['error'].toString());
        }
        throw Exception('OTP verification failed');
      }

      final sessionData = data['session'];
      if (sessionData is! Map) {
        throw Exception('Session data was not returned');
      }

      final refreshToken = sessionData['refresh_token']?.toString();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw Exception('Refresh token was not returned');
      }

      await _supabase.auth.setSession(refreshToken);

      debugPrint('OTP verified. User ID: ${_supabase.auth.currentUser?.id}');

      return data;
    } catch (error) {
      debugPrint('OTP verification error: $error');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  bool get isAuthenticated => _supabase.auth.currentUser != null;

  Future<Map<String, dynamic>?> getUserProfile(String phone) async {
    try {
      final response = await _supabase
          .from('Profiles')
          .select()
          .eq('phone', phone)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }
}
