import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _keyProfileComplete = 'profile_complete';
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyUserPhone = 'user_phone';
  static const _keyDeliveryAddress = 'delivery_address';
  static const _keyDeliveryLabel = 'delivery_label';
  static const _keyDeliveryPhone = 'delivery_phone';

  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  static Future<bool> isProfileComplete() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyProfileComplete) ?? false;
  }

  static Future<void> setProfileComplete({
    required String userId,
    required String name,
    String? phone,
  }) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyProfileComplete, true);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserName, name);
    if (phone != null) await prefs.setString(_keyUserPhone, phone);
  }

  static Future<String?> getUserId() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUserId);
  }

  static Future<String?> getUserName() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUserName);
  }

  static Future<String?> getUserPhone() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUserPhone);
  }

  static Future<void> saveUserPhone(String phone) async {
    final prefs = await _prefs;
    await prefs.setString(_keyUserPhone, phone);
  }

  static Future<void> saveDeliveryAddress({
    required String label,
    required String address,
    required String phone,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_keyDeliveryLabel, label);
    await prefs.setString(_keyDeliveryAddress, address);
    await prefs.setString(_keyDeliveryPhone, phone);
  }

  static Future<Map<String, String>?> getDeliveryAddress() async {
    final prefs = await _prefs;
    final address = prefs.getString(_keyDeliveryAddress);
    if (address == null || address.isEmpty) return null;
    return {
      'label': prefs.getString(_keyDeliveryLabel) ?? 'Home',
      'address': address,
      'phone': prefs.getString(_keyDeliveryPhone) ?? '',
    };
  }

  static Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
