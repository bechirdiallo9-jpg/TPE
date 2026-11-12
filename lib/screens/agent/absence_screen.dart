import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/absence.dart';
import '../../state/demo_store.dart';

class AbsenceScreen extends StatefulWidget {
  const AbsenceScreen({super.key});

  @override
  State<AbsenceScreen> createState() => _AbsenceScreenState();
}

class _AbsenceScreenState extends State<AbsenceScreen> {
  static const reasons = ['Maladie', 'Enfant malade', 'Transport', 'Autre'];
  int _dayOffset = 0;
  String _reason = reasons.first;

  String _dayLabel(int offset) {
    if (offset == 0) return "Aujourd'hui";
    if (offset == 1) return 'Demain';
    return toBeginningOfSentenceCase(
        DateFormat('EEE d MMM', 'fr_FR').format(DateTime.now().add(Duration(days: offset))));
  }

  Future<void> _send() async {
    final store = context.read<DemoStore>();
    final now = DateTime.now();
    store.addAbsence(Absence(
      agentId: store.demoAgent.id,
      date: DateTime(now.year, now.month, now.day + _dayOffset),
      reason: _reason,
    ));
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 56),
        title: const Text('Le gérant est prévenu'),
        content: Text('Absence : ${_dayLabel(_dayOffset).toLowerCase()} · $_reason'),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signaler une absence')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Date', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var d = 0; d < 7; d++)
                ChoiceChip(
                  label: Text(_dayLabel(d), style: const TextStyle(fontSize: 16)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  selected: _dayOffset == d,
                  onSelected: (_) => setState(() => _dayOffset = d),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Motif', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          RadioGroup<String>(
            groupValue: _reason,
            onChanged: (v) => setState(() => _reason = v!),
            child: Column(
              children: [
                for (final r in reasons)
                  RadioListTile<String>(
                    value: r,
                    title: Text(r, style: const TextStyle(fontSize: 18)),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Envoyer'),
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}
