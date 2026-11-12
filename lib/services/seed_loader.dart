import 'dart:convert';

import 'package:flutter/services.dart';

import '../config/demo_config.dart';
import '../models/absence.dart';
import '../models/agent.dart';
import '../models/intervention.dart';
import '../models/site.dart';

class SeedData {
  final String companyName;
  final String demoAgentId;
  final List<String> exampleBefore;
  final List<String> exampleAfter;
  final List<Agent> agents;
  final List<Site> sites;
  final List<Intervention> interventions;
  final List<Absence> absences;

  SeedData({
    required this.companyName,
    required this.demoAgentId,
    required this.exampleBefore,
    required this.exampleAfter,
    required this.agents,
    required this.sites,
    required this.interventions,
    required this.absences,
  });
}

/// Charge le jeu de données du secteur. Les horaires du JSON sont en minutes
/// relatives à maintenant, pour que la démo soit cohérente à toute heure.
class SeedLoader {
  static Future<SeedData> load(Sector sector) async {
    final file = sector == Sector.nettoyage
        ? 'assets/seed_nettoyage.json'
        : 'assets/seed_espaces_verts.json';
    final j = jsonDecode(await rootBundle.loadString(file)) as Map<String, dynamic>;

    // Heures planifiées arrondies à 5 min pour un affichage propre.
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day, now.hour, now.minute - now.minute % 5);
    DateTime at(int minutes) => now.add(Duration(minutes: minutes));

    final taskLabels = List<String>.from(j['tasks']);
    final photos = j['examplePhotos'] as Map<String, dynamic>;

    final interventions = (j['interventions'] as List).map((raw) {
      final i = raw as Map<String, dynamic>;
      final doneCount = i['allTasksDone'] == true ? taskLabels.length : (i['tasksDone'] ?? 0) as int;
      return Intervention(
        id: i['id'],
        agentId: i['agentId'],
        siteId: i['siteId'],
        plannedStart: base.add(Duration(minutes: i['startOffsetMin'])),
        plannedDuration: Duration(minutes: i['durationMin']),
        status: InterventionStatus.values.byName(i['status']),
        arrivedAt: i['arrivedOffsetMin'] == null ? null : at(i['arrivedOffsetMin']),
        leftAt: i['leftOffsetMin'] == null ? null : at(i['leftOffsetMin']),
        tasks: [
          for (var k = 0; k < taskLabels.length; k++)
            TaskItem(label: taskLabels[k], done: k < doneCount),
        ],
        photosBefore: List<String>.from(i['photosBefore'] ?? const []),
        photosAfter: List<String>.from(i['photosAfter'] ?? const []),
        comment: i['comment'] ?? '',
      );
    }).toList()
      ..sort((a, b) => a.plannedStart.compareTo(b.plannedStart));

    final today = DateTime(now.year, now.month, now.day);
    final absences = (j['absences'] as List).map((raw) {
      final a = raw as Map<String, dynamic>;
      return Absence(
        agentId: a['agentId'],
        date: today.add(Duration(days: a['dayOffset'] ?? 0)),
        reason: a['reason'],
        replacementAgentId: a['replacementAgentId'],
      );
    }).toList();

    return SeedData(
      companyName: j['companyName'],
      demoAgentId: j['demoAgentId'],
      exampleBefore: List<String>.from(photos['before']),
      exampleAfter: List<String>.from(photos['after']),
      agents: (j['agents'] as List).map((a) => Agent.fromJson(a)).toList(),
      sites: (j['sites'] as List).map((s) => Site.fromJson(s)).toList(),
      interventions: interventions,
      absences: absences,
    );
  }
}
