import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

enum Sector { nettoyage, espacesVerts }

/// Réglages de rebranding, conservés dans un fichier JSON de l'app.
class DemoConfig {
  Sector sector;
  String? companyName; // null = nom du jeu de données
  String? logoPath; // null = logo par défaut
  int colorValue;

  DemoConfig({
    this.sector = Sector.nettoyage,
    this.companyName,
    this.logoPath,
    int? colorValue,
  }) : colorValue = colorValue ?? palette.first.toARGB32();

  /// Les 6 couleurs proposées (ni rouge ni vert : réservés aux retards et au « terminé »).
  static const palette = <Color>[
    Color(0xFF1565C0), // bleu
    Color(0xFF00796B), // sarcelle
    Color(0xFF3949AB), // indigo
    Color(0xFF6A1B9A), // violet
    Color(0xFFE65100), // orange
    Color(0xFF37474F), // ardoise
  ];

  Color get color => Color(colorValue);

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/settings.json');
  }

  static Future<DemoConfig> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return DemoConfig();
      final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      final logo = j['logoPath'] as String?;
      return DemoConfig(
        sector: Sector.values.byName(j['sector'] ?? 'nettoyage'),
        companyName: j['companyName'],
        logoPath: (logo != null && File(logo).existsSync()) ? logo : null,
        colorValue: j['colorValue'],
      );
    } catch (_) {
      // Un fichier abîmé ne doit jamais empêcher la démo de démarrer.
      return DemoConfig();
    }
  }

  Future<void> save() async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode({
        'sector': sector.name,
        'companyName': companyName,
        'logoPath': logoPath,
        'colorValue': colorValue,
      }));
    } catch (_) {}
  }
}
