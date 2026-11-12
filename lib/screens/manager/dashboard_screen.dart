import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/agent.dart';
import '../../models/intervention.dart';
import '../../state/demo_store.dart';
import '../../widgets/role_switch.dart';
import '../../widgets/status_chip.dart';
import 'report_preview_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Rafraîchit chaque minute pour que les retards apparaissent avec le temps.
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _openReport(Intervention i) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReportPreviewScreen(interventionId: i.id)),
      );

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DemoStore>();
    final hm = DateFormat.Hm();

    // Une ligne par agent : intervention en retard, sinon en cours, sinon la prochaine.
    final rows = <_AgentRow>[];
    for (final agent in store.agents) {
      final list = store.interventionsOf(agent.id);
      Intervention? pick(bool Function(Intervention) test) => list.where(test).firstOrNull;
      final shown = pick((i) => i.isLate) ??
          pick((i) => i.status == InterventionStatus.onSite) ??
          pick((i) => i.status == InterventionStatus.enRoute) ??
          pick((i) => i.status == InterventionStatus.planned) ??
          list.lastOrNull;
      rows.add(_AgentRow(agent, shown, store.isAbsentToday(agent.id)));
    }
    int rank(_AgentRow r) => r.absent ? 2 : (r.intervention?.isLate ?? false) ? 0 : 1;
    rows.sort((a, b) => rank(a).compareTo(rank(b)));

    final done = store.interventions.where((i) => i.status == InterventionStatus.done).toList()
      ..sort((a, b) => b.leftAt!.compareTo(a.leftAt!));

    return Scaffold(
      appBar: brandAppBar(context),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _Counter('En route', store.countStatus(InterventionStatus.enRoute), StatusColors.enRoute),
              _Counter('Sur site', store.countStatus(InterventionStatus.onSite), StatusColors.onSite),
              _Counter('Terminées', store.countStatus(InterventionStatus.done), StatusColors.done),
              _Counter('En retard', store.lateCount,
                  store.lateCount > 0 ? StatusColors.late : StatusColors.planned,
                  highlight: store.lateCount > 0),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Équipe'),
          for (final r in rows) _agentTile(store, r, hm),
          const SizedBox(height: 16),
          const _SectionTitle('Absences du jour'),
          if (store.todayAbsences.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Aucune absence', style: TextStyle(fontSize: 17)),
            ),
          for (final a in store.todayAbsences)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  minTileHeight: 64,
                  leading: const Icon(Icons.event_busy, color: StatusColors.absent, size: 32),
                  title: Text('${store.agentById(a.agentId).displayName} · ${a.reason}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    a.replacementAgentId != null
                        ? 'Remplacé(e) par ${store.agentById(a.replacementAgentId!).displayName}'
                        : 'Remplaçant à trouver',
                    style: TextStyle(
                      fontSize: 16,
                      color: a.replacementAgentId != null ? null : StatusColors.late,
                      fontWeight: a.replacementAgentId != null ? null : FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const _SectionTitle('Rapports du jour'),
          for (final i in done)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  minTileHeight: 64,
                  onTap: () => _openReport(i),
                  leading: const Icon(Icons.picture_as_pdf, color: StatusColors.done, size: 32),
                  title: Text(store.siteById(i.siteId).clientName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${store.agentById(i.agentId).displayName} · terminée à ${hm.format(i.leftAt!)}',
                      style: const TextStyle(fontSize: 16)),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _agentTile(DemoStore store, _AgentRow r, DateFormat hm) {
    final i = r.intervention;
    final late = i?.isLate ?? false;
    final site = i == null ? null : store.siteById(i.siteId);
    String subtitle;
    if (r.absent) {
      subtitle = 'Absent aujourd\'hui';
    } else if (i == null || site == null) {
      subtitle = 'Aucune intervention';
    } else if (late) {
      subtitle = '${site.clientName} · prévue à ${hm.format(i.plannedStart)}, non démarrée';
    } else if (i.status == InterventionStatus.planned) {
      subtitle = 'Prochaine : ${site.clientName} · ${hm.format(i.plannedStart)}';
    } else if (i.status == InterventionStatus.done) {
      subtitle = 'Journée terminée · ${site.clientName}';
    } else {
      subtitle = '${site.clientName} · ${site.city}';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: late ? const Color(0xFFFDECEA) : null,
        shape: late
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: StatusColors.late, width: 2),
              )
            : null,
        child: ListTile(
          minTileHeight: 72,
          onTap: (i != null && i.status == InterventionStatus.done) ? () => _openReport(i) : null,
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: late ? StatusColors.late : Theme.of(context).colorScheme.primaryContainer,
            child: Text(r.agent.firstName[0],
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: late ? Colors.white : null)),
          ),
          title: Text(r.agent.displayName,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: late ? StatusColors.late : null)),
          subtitle: Text(subtitle,
              style: TextStyle(fontSize: 15, color: late ? StatusColors.late : null)),
          trailing: r.absent
              ? const StatusChip.absent()
              : (i == null ? null : StatusChip.of(i)),
        ),
      ),
    );
  }
}

class _AgentRow {
  final Agent agent;
  final Intervention? intervention;
  final bool absent;

  _AgentRow(this.agent, this.intervention, this.absent);
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool highlight;

  const _Counter(this.label, this.value, this.color, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: highlight ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, color: highlight ? Colors.white : color)),
            FittedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: highlight ? Colors.white : Colors.black87)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      );
}
