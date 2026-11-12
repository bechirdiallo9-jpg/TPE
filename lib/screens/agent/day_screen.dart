import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/demo_store.dart';
import '../../widgets/role_switch.dart';
import '../../widgets/status_chip.dart';
import 'absence_screen.dart';
import 'intervention_screen.dart';

class DayScreen extends StatelessWidget {
  const DayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DemoStore>();
    final agent = store.demoAgent;
    final items = store.interventionsOf(agent.id);
    final today = toBeginningOfSentenceCase(DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now()));

    return Scaffold(
      appBar: brandAppBar(context),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Bonjour ${agent.firstName}',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(today, style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
          const SizedBox(height: 20),
          Text('Mes interventions (${items.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (final i in items) ...[
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => InterventionScreen(interventionId: i.id)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(DateFormat.Hm().format(i.plannedStart),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(store.siteById(i.siteId).clientName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            Text(store.siteById(i.siteId).city,
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip.of(i),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.event_busy),
            label: const Text('Signaler une absence'),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AbsenceScreen())),
          ),
        ],
      ),
    );
  }
}
