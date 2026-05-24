import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_colors.dart';

class MonProfilScreen extends StatefulWidget {
  const MonProfilScreen({super.key});
  @override
  State<MonProfilScreen> createState() => _MonProfilScreenState();
}

class _MonProfilScreenState extends State<MonProfilScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _ageCtrl     = TextEditingController();
  final _weightCtrl  = TextEditingController();
  final _heightCtrl  = TextEditingController();

  String _diabeteType = 'Type 2';
  bool _loading = true;
  bool _saving  = false;

  final _types = ['Type 1', 'Type 2', 'Pré-diabète', 'Gestationnel'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _loading = false); return; }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      if (doc.exists) {
        final d = doc.data()!;
        _nameCtrl.text   = d['name']   ?? '';
        _phoneCtrl.text  = d['phone']  ?? '';
        _ageCtrl.text    = d['age']?.toString()    ?? '';
        _weightCtrl.text = d['weight']?.toString() ?? '';
        _heightCtrl.text = d['height']?.toString() ?? '';
        _diabeteType     = d['diabeteType'] ?? 'Type 2';
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .set({
        'name':        _nameCtrl.text.trim(),
        'phone':       _phoneCtrl.text.trim(),
        'age':         int.tryParse(_ageCtrl.text)        ?? 0,
        'weight':      double.tryParse(_weightCtrl.text)  ?? 0,
        'height':      double.tryParse(_heightCtrl.text)  ?? 0,
        'diabeteType': _diabeteType,
        'email':       user.email,
        'updatedAt':   FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        _snack('✅ Profil mis à jour !');
        Navigator.pop(context);
      }
    } catch (_) {
      _snack('Erreur lors de la sauvegarde', error: true);
    }
    setState(() => _saving = false);
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: error ? Colors.red : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _ageCtrl.dispose();
    _weightCtrl.dispose(); _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mon profil',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(children: [

                  // ── Hero avatar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.9), AppColors.primary],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        child: Text(initials, style: const TextStyle(
                            fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(height: 12),
                      Text(_nameCtrl.text.isEmpty ? 'Nom complet' : _nameCtrl.text,
                          style: const TextStyle(color: Colors.white, fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(FirebaseAuth.instance.currentUser?.email ?? '',
                          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20)),
                        child: Text(_diabeteType,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 28),

                  // ── Infos personnelles
                  _sectionLabel('INFORMATIONS PERSONNELLES'),
                  const SizedBox(height: 12),
                  _Field(ctrl: _nameCtrl,   label: 'Nom complet',  icon: Icons.person_outline_rounded,
                      validator: (v) => v!.isEmpty ? 'Requis' : null),
                  _Field(ctrl: _phoneCtrl,  label: 'Téléphone',    icon: Icons.phone_outlined,
                      type: TextInputType.phone),

                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _Field(ctrl: _ageCtrl,    label: 'Âge',       icon: Icons.cake_outlined,          type: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _Field(ctrl: _weightCtrl, label: 'Poids (kg)', icon: Icons.monitor_weight_outlined, type: TextInputType.number)),
                  ]),
                  _Field(ctrl: _heightCtrl, label: 'Taille (cm)', icon: Icons.height_rounded,
                      type: TextInputType.number),

                  const SizedBox(height: 20),

                  // ── Type diabète
                  _sectionLabel('TYPE DE DIABÈTE'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _diabeteType,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                        items: _types.map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t, style: const TextStyle(fontSize: 15)))).toList(),
                        onChanged: (v) => setState(() => _diabeteType = v!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      child: _saving
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Enregistrer',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ]),
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
        color: AppColors.primary, letterSpacing: 1.2)),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType type;
  final String? Function(String?)? validator;

  const _Field({required this.ctrl, required this.label, required this.icon,
      this.type = TextInputType.text, this.validator});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl, keyboardType: type, validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );
}