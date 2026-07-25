import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static String _generateUserId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    return '${bytes.sublist(0, 4).map(hex).join()}-'
        '${bytes.sublist(4, 6).map(hex).join()}-'
        '${bytes.sublist(6, 8).map(hex).join()}-'
        '${bytes.sublist(8, 10).map(hex).join()}-'
        '${bytes.sublist(10, 16).map(hex).join()}';
  }

  // 1. ඇත්තටම OTP verify කරන කොටස
  Future<void> loginWithPhone(String phone, String otp) async {
    await _supabase.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );
  }

  // 2. Dummy OTP එක යවන Function එක
  Future<String> sendDummyOTP(String phoneNumber) async {
    await Future.delayed(const Duration(seconds: 2));

    String dummyOtp = "1234";

    print("=======================================");
    print("Mock SMS: Sent to $phoneNumber | OTP Code: $dummyOtp");
    print("=======================================");

    return dummyOtp;
  }

  // 3. Profile save — Supabase sync is best-effort; always returns userId for local session.
  Future<String> saveUserProfile({
    required String name,
    String? email,
    String? gender,
    String? birthday,
    String? phone,
    String? existingUserId,
  }) async {
    final user = _supabase.auth.currentUser;
    final userId = existingUserId ?? user?.id ?? _generateUserId();

    final payload = <String, dynamic>{
      'id': userId,
      'name': name,
    };

    final trimmedEmail = email?.trim();
    if (trimmedEmail != null && trimmedEmail.isNotEmpty) {
      payload['email'] = trimmedEmail;
    }
    if (gender != null && gender.isNotEmpty) {
      payload['gender'] = gender;
    }
    if (birthday != null && birthday.isNotEmpty) {
      payload['birthday'] = birthday;
    }
    if (phone != null && phone.isNotEmpty) {
      payload['phone'] = phone;
    }

    try {
      await _supabase.from('Profiles').upsert(payload);
    } catch (e) {
      debugPrint('Profile Supabase sync error: $e');
      rethrow;
    }

    return userId;
  }

  Future<bool> checkUserExists(String phone) async {
    try {
      final response = await _supabase
          .from('Profiles')
          .select('id')
          .eq('phone', phone)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Error checking user exists: $e');
      return false;
    }
  }

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

  Future<void> saveDeliveryAddress({
    required String userId,
    required String label,
    required String address,
    required String phone,
  }) async {
    debugPrint(
        '[saveDeliveryAddress] userId=$userId label=$label address=$address phone=$phone');
    try {
      final payload = {
        'delivery_label': label,
        'delivery_address': address,
        'delivery_phone': phone,
      };
      final response = await _supabase
          .from('Profiles')
          .update(payload)
          .eq('id', userId)
          .select();
      debugPrint('[saveDeliveryAddress] update response: $response');
    } catch (e) {
      debugPrint('[saveDeliveryAddress] error: $e');
    }
  }

  Future<Map<String, dynamic>?> getDeliveryAddress(String userId) async {
    try {
      final response = await _supabase
          .from('Profiles')
          .select('delivery_address, delivery_label, delivery_phone')
          .eq('id', userId)
          .maybeSingle();
      if (response != null &&
          response['delivery_address'] != null &&
          (response['delivery_address'] as String).isNotEmpty) {
        return response;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching delivery address: $e');
      return null;
    }
  }
}
