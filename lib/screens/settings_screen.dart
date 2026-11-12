import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../config/demo_config.dart';
import '../state/demo_store.dart';
import '../widgets/photo_view.dart';

/// Écran caché (appui long sur le logo) : personnaliser la démo pour un prospect.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name =
      TextEditingController(text: context.read<DemoStore>().companyName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text, style: const TextStyle(fontSize: 16))));

  Future<void> _pickLogo() async {
    final store = context.read<DemoStore>();
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512);
      if (picked == null) return;
      // Copie dans le dossier de l'app pour que le logo survive aux redémarrages.
      final dir = await getApplicationDocumentsDirectory();
      final ext = picked.path.contains('.') ? picked.path.split('.').last : 'png';
      final dest = '${dir.path}/logo_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(picked.path).copy(dest);
      await store.setLogo(dest);
    } catch (_) {
      _snack('Galerie indisponible');
    }
  }

  Future<void> _changeSector(Sector s) async {
    final store = context.read<DemoStore>();
    await store.setSector(s);
    _name.text = store.companyName;
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser la démo ?'),
        content: const Text('Toutes les interventions et absences reviennent à leur état initial. '
            "Le nom, le logo et la couleur sont conservés."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Réinitialiser')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<DemoStore>().resetDemo();
    _snack('Démo réinitialisée');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DemoStore>();
    const title = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(title: const Text('Personnaliser la démo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Secteur', style: title),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: SegmentedButton<Sector>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: Sector.nettoyage, label: Text('Nettoyage'), icon: Icon(Icons.cleaning_services)),
                ButtonSegment(value: Sector.espacesVerts, label: Text('Espaces verts'), icon: Icon(Icons.park)),
              ],
              selected: {store.config.sector},
              onSelectionChanged: (s) => _changeSector(s.first),
            ),
          ),
          const SizedBox(height: 28),
          const Text("Nom de l'entreprise", style: title),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            style: const TextStyle(fontSize: 18),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onChanged: store.setCompanyName,
          ),
          const SizedBox(height: 28),
          const Text('Logo', style: title),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: LogoImage(path: store.config.logoPath),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choisir dans la galerie'),
                      onPressed: _pickLogo,
                    ),
                    if (store.config.logoPath != null)
                      TextButton(
                        onPressed: () => store.setLogo(null),
                        child: const Text('Logo par défaut'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Couleur principale', style: title),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final c in DemoConfig.palette)
                GestureDetector(
                  onTap: () => store.setColor(c.toARGB32()),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: store.config.colorValue == c.toARGB32() ? Colors.black : Colors.transparent,
                        width: 4,
                      ),
                    ),
                    child: store.config.colorValue == c.toARGB32()
                        ? const Icon(Icons.check, color: Colors.white, size: 28)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 36),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
              side: const BorderSide(color: Color(0xFFC62828), width: 2),
            ),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Réinitialiser la démo'),
            onPressed: _reset,
          ),
        ],
      ),
    );
  }
}
