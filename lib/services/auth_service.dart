import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../database/db_helper.dart';

class AuthService {
  static String _hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  static Future<bool> hasPin() async {
    final saved = await DbHelper.instance.getSetting('pin_hash');
    return saved != null;
  }

  static Future<void> setPin(String pin) async {
    final random = Random.secure();
    final salt = base64UrlEncode(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    await DbHelper.instance.setSetting('pin_salt', salt);
    await DbHelper.instance.setSetting('pin_hash', _hash(pin, salt));
  }

  static Future<bool> verifyPin(String pin) async {
    final salt = await DbHelper.instance.getSetting('pin_salt');
    final saved = await DbHelper.instance.getSetting('pin_hash');
    if (salt == null || saved == null) return false;
    return _hash(pin, salt) == saved;
  }
}