import 'package:flutter/material.dart';

import '../models/intervention.dart';

/// Couleurs fixes : rouge réservé aux retards, vert réservé au « terminé ».
class StatusColors {
  static const late = Color(0xFFC62828);
  static const done = Color(0xFF2E7D32);
  static const onSite = Color(0xFF1565C0);
  static const enRoute = Color(0xFFB45309);
  static const planned = Color(0xFF546E7A);
  static const absent = Color(0xFF6D4C41);
}

/// Pastille de statut, identique partout dans l'app.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  factory StatusChip.of(Intervention i) {
    if (i.isLate) return const StatusChip(label: 'En retard', color: StatusColors.late);
    return switch (i.status) {
      InterventionStatus.planned => const StatusChip(label: 'Prévue', color: StatusColors.planned),
      InterventionStatus.enRoute => const StatusChip(label: 'En route', color: StatusColors.enRoute),
      InterventionStatus.onSite => const StatusChip(label: 'Sur site', color: StatusColors.onSite),
      InterventionStatus.done => const StatusChip(label: 'Terminée', color: StatusColors.done),
    };
  }

  const StatusChip.absent({super.key})
      : label = 'Absent',
        color = StatusColors.absent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
