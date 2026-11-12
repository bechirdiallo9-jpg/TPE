// Test de fumée : le parcours de démo complet, sans caméra ni réseau.
import 'package:equipe_terrain/config/demo_config.dart';
import 'package:equipe_terrain/main.dart';
import 'package:equipe_terrain/models/intervention.dart';
import 'package:equipe_terrain/services/pdf_report.dart';
import 'package:equipe_terrain/state/demo_store.dart';
import 'package:equipe_terrain/widgets/photo_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<DemoStore> _boot(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 7000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await initializeDateFormatting('fr_FR');
  Intl.defaultLocale = 'fr_FR';
  final store = DemoStore();
  await tester.runAsync(store.init);
  await tester.pumpWidget(ChangeNotifierProvider.value(value: store, child: const DemoApp()));
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('Parcours de Karim et tableau de bord', (tester) async {
    final store = await _boot(tester);

    // Jeu de données : 12 interventions, exactement 1 en retard.
    expect(store.interventions.length, 12);
    expect(store.lateCount, 1);
    expect(find.text('Bonjour Karim'), findsOneWidget);

    // Côté gérant, état initial.
    await tester.tap(find.text('Gérant'));
    await tester.pumpAndSettle();
    expect(store.countStatus(InterventionStatus.done), 3);
    expect(find.text('En retard'), findsWidgets);
    expect(find.textContaining('Remplacé(e) par Nadia R.'), findsOneWidget);

    // Retour côté agent : intervention dans 30 min.
    await tester.tap(find.text('Agent'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cabinet médical du Lys'));
    await tester.pumpAndSettle();

    await tester.tap(find.text("J'arrive"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Utiliser une photo d'exemple").first);
    await tester.pumpAndSettle();
    for (final label in ['Sols aspirés et lavés', 'Sanitaires désinfectés', 'Poubelles vidées']) {
      await tester.tap(find.text(label));
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text("Utiliser une photo d'exemple").last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminer'));
    await tester.pumpAndSettle();
    expect(find.text('Rapport envoyé au client'), findsOneWidget);
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();

    final i = store.interventionById('i2');
    expect(i.status, InterventionStatus.done);
    expect(i.photosBefore.length, 1);
    expect(i.photosAfter.length, 1);
    expect(i.tasks.where((t) => t.done).length, 3);

    // Le PDF se génère rapidement.
    final sw = Stopwatch()..start();
    final bytes = await tester.runAsync(() => PdfReport.build(store, i));
    sw.stop();
    expect(bytes!.length, greaterThan(10000));
    expect(sw.elapsedMilliseconds, lessThan(3000));

    // Le tableau de bord reflète l'action, sans redémarrer.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gérant'));
    await tester.pumpAndSettle();
    expect(store.countStatus(InterventionStatus.done), 4);
    expect(find.text('Cabinet médical du Lys'), findsOneWidget); // dans « Rapports du jour »

    // Appui long sur le logo -> réglages cachés -> Réinitialiser.
    await tester.longPress(find.byType(LogoImage));
    await tester.pumpAndSettle();
    expect(find.text('Personnaliser la démo'), findsOneWidget);
    await tester.ensureVisible(find.text('Réinitialiser la démo'));
    await tester.tap(find.text('Réinitialiser la démo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Réinitialiser'));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(store.countStatus(InterventionStatus.done), 3);
    expect(store.interventionById('i2').status, InterventionStatus.planned);
  });

  testWidgets('Changement de secteur', (tester) async {
    final store = await _boot(tester);
    await tester.runAsync(() => store.setSector(Sector.espacesVerts));
    await tester.pumpAndSettle();
    expect(store.companyName, 'Oise Jardins Services');
    expect(store.interventions.first.tasks.first.label, 'Tonte');
    expect(find.text('Oise Jardins Services'), findsOneWidget);
    final bytes = await tester.runAsync(() => PdfReport.build(store, store.interventionById('i1')));
    expect(bytes!.length, greaterThan(10000));
  });
}
