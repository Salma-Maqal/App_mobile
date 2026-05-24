import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple in-memory + SharedPreferences user session.
class UserSession extends ChangeNotifier {
  static final UserSession _i = UserSession._();
  factory UserSession() => _i;
  UserSession._();

  String _nom    = '';
  String _prenom = '';
  String _email  = '';
  String? _photoPath; // local file path

  String get nom       => _nom;
  String get prenom    => _prenom;
  String get email     => _email;
  String get fullName  => '$_prenom $_nom'.trim();
  String? get photoPath => _photoPath;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _nom       = p.getString('nom')    ?? '';
    _prenom    = p.getString('prenom') ?? '';
    _email     = p.getString('email')  ?? '';
    _photoPath = p.getString('photo');
    notifyListeners();
  }

  Future<void> save({
    String? nom, String? prenom, String? email, String? photoPath,
  }) async {
    final p = await SharedPreferences.getInstance();
    if (nom    != null) { _nom    = nom;    await p.setString('nom',    nom); }
    if (prenom != null) { _prenom = prenom; await p.setString('prenom', prenom); }
    if (email  != null) { _email  = email;  await p.setString('email',  email); }
    if (photoPath != null) { _photoPath = photoPath; await p.setString('photo', photoPath); }
    notifyListeners();
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    _nom = _prenom = _email = '';
    _photoPath = null;
    notifyListeners();
  }
}
