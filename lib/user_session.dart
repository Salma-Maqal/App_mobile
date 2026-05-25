import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simple in-memory + SharedPreferences user session.
class UserSession extends ChangeNotifier {
  static final UserSession _i = UserSession._();
  factory UserSession() => _i;
  UserSession._();

  String _nom    = '';
  String _prenom = '';
  String _email  = '';
  String? _photoPath;
  String _role   = 'diabetique'; // Ajout du rôle

  String get nom       => _nom;
  String get prenom    => _prenom;
  String get email     => _email;
  String get fullName  => '$_prenom $_nom'.trim();
  String? get photoPath => _photoPath;
  String get role      => _role;
  bool get isDiabetic  => _role == 'diabetique';
  bool get isCompanion => _role == 'accompagnant';
  bool get isLoggedIn  => _email.isNotEmpty;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _nom       = p.getString('nom')    ?? '';
    _prenom    = p.getString('prenom') ?? '';
    _email     = p.getString('email')  ?? '';
    _photoPath = p.getString('photo');
    _role      = p.getString('role')   ?? 'diabetique'; // Chargement du rôle
    notifyListeners();
  }

  Future<void> save({
    String? nom,
    String? prenom,
    String? email,
    String? photoPath,
    String? role,
  }) async {
    final p = await SharedPreferences.getInstance();
    
    // ── Sauvegarde locale ──
    if (nom != null) {
      _nom = nom;
      await p.setString('nom', nom);
    }
    if (prenom != null) {
      _prenom = prenom;
      await p.setString('prenom', prenom);
    }
    if (email != null) {
      _email = email;
      await p.setString('email', email);
    }
    if (photoPath != null) {
      _photoPath = photoPath;
      await p.setString('photo', photoPath);
    }
    if (role != null) {
      _role = role;
      await p.setString('role', role);
    }

    // ── Synchronisation avec Firestore ──
    await _syncToFirestore(
      nom: nom,
      prenom: prenom,
      email: email,
      role: role,
    );

    notifyListeners();
  }

  /// Synchronise les données utilisateur avec Firestore
  Future<void> _syncToFirestore({
    String? nom,
    String? prenom,
    String? email,
    String? role,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      final Map<String, dynamic> data = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Ajout du nom complet si nom ou prénom a changé
      if (nom != null || prenom != null) {
        data['name'] = fullName;
      }
      
      if (email != null) data['email'] = email;
      if (role != null) data['role'] = role;
      
      // Ajout des champs optionnels
      if (_photoPath != null) data['photoUrl'] = _photoPath;
      
      await userDoc.set(data, SetOptions(merge: true));
      debugPrint('User data synced to Firestore: ${user.uid}');
    } catch (e) {
      debugPrint('Error syncing to Firestore: $e');
    }
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    _nom = '';
    _prenom = '';
    _email = '';
    _photoPath = null;
    _role = 'diabetique';
    notifyListeners();
  }
}