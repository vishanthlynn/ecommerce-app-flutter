import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  SharedPreferences? _prefs;
  String? token;
  String? name;
  String? email;
  String? userId;
  String? phone;

  bool get signedIn => token != null && token!.isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    token = _prefs!.getString('token');
    name = _prefs!.getString('name');
    email = _prefs!.getString('email');
    userId = _prefs!.getString('userId');
    phone = _prefs!.getString('phone');
  }

  Future<void> save({
    required String token,
    required String name,
    required String email,
    required String userId,
    String phone = '',
  }) async {
    this.token = token;
    this.name = name;
    this.email = email;
    this.userId = userId;
    this.phone = phone;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('userId', userId);
    await prefs.setString('phone', phone);
  }

  Future<void> clear() async {
    token = null;
    name = null;
    email = null;
    userId = null;
    phone = null;
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove('token');
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('userId');
    await prefs.remove('phone');
  }
}
