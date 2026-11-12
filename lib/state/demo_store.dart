import 'package:flutter/foundation.dart';

import '../config/demo_config.dart';
import '../models/absence.dart';
import '../models/agent.dart';
import '../models/intervention.dart';
import '../models/site.dart';
import '../services/seed_loader.dart';

/// L'unique état de l'app. L'écran agent et le tableau de bord gérant
/// lisent les mêmes objets : une action de l'agent est visible tout de suite.
class DemoStore extends ChangeNotifier {
  DemoConfig config = DemoConfig();
  late SeedData _seed;
  bool isManager = false;

  List<Agent> get agents => _seed.agents;
  List<Site> get sites => _seed.sites;
  List<Intervention> get interventions => _seed.interventions;
  List<Absence> get absences => _seed.absences;

  String get companyName =>
      (config.companyName?.trim().isNotEmpty ?? false) ? config.companyName!.trim() : _seed.companyName;
  Agent get demoAgent => agentById(_seed.demoAgentId);

  Future<void> init() async {
    config = await DemoConfig.load();
    _seed = await SeedLoader.load(config.sector);
  }

  // ---------- Lecture ----------

  Agent agentById(String id) => agents.firstWhere((a) => a.id == id);
  Site siteById(String id) => sites.firstWhere((s) => s.id == id);
  Intervention interventionById(String id) => interventions.firstWhere((i) => i.id == id);

  List<Intervention> interventionsOf(String agentId) =>
      interventions.where((i) => i.agentId == agentId).toList();

  int countStatus(InterventionStatus s) => interventions.where((i) => i.status == s).length;
  int get lateCount => interventions.where((i) => i.isLate).length;

  List<Absence> get todayAbsences {
    final now = DateTime.now();
    return absences
        .where((a) => a.date.year == now.year && a.date.month == now.month && a.date.day == now.day)
        .toList();
  }

  bool isAbsentToday(String agentId) => todayAbsences.any((a) => a.agentId == agentId);

  // ---------- Actions ----------

  void setManager(bool value) {
    isManager = value;
    notifyListeners();
  }

  void markArrived(Intervention i) {
    i.status = InterventionStatus.onSite;
    i.arrivedAt = DateTime.now();
    notifyListeners();
  }

  void toggleTask(TaskItem t) {
    t.done = !t.done;
    notifyListeners();
  }

  void addPhoto(Intervention i, {required bool before, required String path}) {
    (before ? i.photosBefore : i.photosAfter).add(path);
    notifyListeners();
  }

  void removePhoto(Intervention i, {required bool before, required String path}) {
    (before ? i.photosBefore : i.photosAfter).remove(path);
    notifyListeners();
  }

  /// Ajoute une photo d'exemple. La n-ième photo « après » correspond à la
  /// n-ième photo « avant » (même scène), pour des paires cohérentes.
  void addExamplePhoto(Intervention i, {required bool before}) {
    final list = before ? _seed.exampleBefore : _seed.exampleAfter;
    final current = before ? i.photosBefore : i.photosAfter;
    addPhoto(i, before: before, path: list[current.length % list.length]);
  }

  void setComment(Intervention i, String text) {
    i.comment = text; // pas de notify : évite de reconstruire à chaque frappe
  }

  void finish(Intervention i) {
    i.status = InterventionStatus.done;
    i.leftAt = DateTime.now();
    notifyListeners();
  }

  void addAbsence(Absence a) {
    absences.add(a);
    notifyListeners();
  }

  // ---------- Rebranding ----------

  Future<void> setSector(Sector s) async {
    config.sector = s;
    config.companyName = null; // reprend le nom du jeu de données
    _seed = await SeedLoader.load(s);
    await config.save();
    notifyListeners();
  }

  Future<void> setCompanyName(String name) async {
    config.companyName = name;
    await config.save();
    notifyListeners();
  }

  Future<void> setLogo(String? path) async {
    config.logoPath = path;
    await config.save();
    notifyListeners();
  }

  Future<void> setColor(int value) async {
    config.colorValue = value;
    await config.save();
    notifyListeners();
  }

  /// Remet toutes les interventions et absences dans leur état initial.
  Future<void> resetDemo() async {
    _seed = await SeedLoader.load(config.sector);
    notifyListeners();
  }
}
