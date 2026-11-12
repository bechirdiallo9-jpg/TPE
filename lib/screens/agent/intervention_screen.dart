import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/intervention.dart';
import '../../state/demo_store.dart';
import '../../widgets/photo_view.dart';
import '../../widgets/status_chip.dart';
import '../manager/report_preview_screen.dart';

class InterventionScreen extends StatefulWidget {
  final String interventionId;

  const InterventionScreen({super.key, required this.interventionId});

  @override
  State<InterventionScreen> createState() => _InterventionScreenState();
}

class _InterventionScreenState extends State<InterventionScreen> {
  late final TextEditingController _comment;

  @override
  void initState() {
    super.initState();
    final i = context.read<DemoStore>().interventionById(widget.interventionId);
    _comment = TextEditingController(text: i.comment);
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text, style: const TextStyle(fontSize: 16))));
  }

  Future<void> _itinerary(String address) async {
    // Paquets limités à la liste du brief : on copie l'adresse plutôt que
    // d'ouvrir l'app de cartes. Jamais bloquant.
    await Clipboard.setData(ClipboardData(text: address));
    _snack('Adresse copiée : collez-la dans votre app de cartes');
  }

  Future<void> _takePhoto(Intervention i, {required bool before}) async {
    final store = context.read<DemoStore>();
    try {
      final file = await ImagePicker()
          .pickImage(source: ImageSource.camera, maxWidth: 1024, imageQuality: 70);
      if (file != null) store.addPhoto(i, before: before, path: file.path);
    } catch (_) {
      // Permission refusée, pas de caméra (simulateur)... la démo continue.
      _snack("Appareil photo indisponible : utilisez une photo d'exemple");
    }
  }

  Future<void> _finish(Intervention i) async {
    final store = context.read<DemoStore>();
    store.setComment(i, _comment.text.trim());
    store.finish(i);
    final seeReport = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.mark_email_read, color: StatusColors.done, size: 56),
        title: const Text('Rapport envoyé au client'),
        content: const Text("Le client a reçu le rapport d'intervention avec les photos."),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowDirection: VerticalDirection.up,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Fermer')),
          FilledButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => Navigator.pop(ctx, true),
            label: const Text('Voir le rapport'),
          ),
        ],
      ),
    );
    if (seeReport == true && mounted) _openReport(i);
  }

  void _openReport(Intervention i) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReportPreviewScreen(interventionId: i.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DemoStore>();
    final i = store.interventionById(widget.interventionId);
    final site = store.siteById(i.siteId);
    final hm = DateFormat.Hm();
    final started = i.status == InterventionStatus.onSite || i.status == InterventionStatus.done;
    final done = i.status == InterventionStatus.done;

    return Scaffold(
      appBar: AppBar(title: Text(site.clientName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Prévue à ${hm.format(i.plannedStart)} · ${i.plannedDuration.inMinutes} min',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              StatusChip.of(i),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Consignes et adresse
          _Step(
            number: 1,
            title: 'Adresse et consignes',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(site.address, style: const TextStyle(fontSize: 18)),
                Text(site.city, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4D6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5B94A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.vpn_key, color: Color(0xFF8A5A00)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(site.instructions, style: const TextStyle(fontSize: 17))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.directions),
                  label: const Text('Itinéraire'),
                  onPressed: () => _itinerary(site.fullAddress),
                ),
              ],
            ),
          ),

          // 2. Arrivée
          if (!started)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(72)),
                icon: const Icon(Icons.location_on, size: 30),
                label: const Text("J'arrive", style: TextStyle(fontSize: 24)),
                onPressed: () => store.markArrived(i),
              ),
            )
          else ...[
            _InfoLine(
              icon: Icons.login,
              text: 'Arrivé à ${hm.format(i.arrivedAt!)}'
                  '${done ? ' · Parti à ${hm.format(i.leftAt!)}' : ''}',
            ),

            // 3. Photos avant
            _Step(
              number: 2,
              title: 'Photos avant',
              child: _PhotoSection(
                photos: i.photosBefore,
                readOnly: done,
                onCamera: () => _takePhoto(i, before: true),
                onExample: () => store.addExamplePhoto(i, before: true),
                onRemove: (p) => store.removePhoto(i, before: true, path: p),
              ),
            ),

            // 4. Checklist
            _Step(
              number: 3,
              title: 'Tâches (${i.tasks.where((t) => t.done).length}/${i.tasks.length})',
              child: Column(
                children: [
                  for (final t in i.tasks)
                    CheckboxListTile(
                      value: t.done,
                      onChanged: done ? null : (_) => store.toggleTask(t),
                      title: Text(t.label, style: const TextStyle(fontSize: 18)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: StatusColors.done,
                    ),
                ],
              ),
            ),

            // 5. Photos après + commentaire
            _Step(
              number: 4,
              title: 'Photos après',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PhotoSection(
                    photos: i.photosAfter,
                    readOnly: done,
                    onCamera: () => _takePhoto(i, before: false),
                    onExample: () => store.addExamplePhoto(i, before: false),
                    onRemove: (p) => store.removePhoto(i, before: false, path: p),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _comment,
                    enabled: !done,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 17),
                    onChanged: (v) => store.setComment(i, v),
                    decoration: const InputDecoration(
                      labelText: 'Commentaire (facultatif)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            if (!done)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(72),
                  backgroundColor: StatusColors.done,
                ),
                icon: const Icon(Icons.check_circle, size: 30),
                label: const Text('Terminer', style: TextStyle(fontSize: 24)),
                onPressed: () => _finish(i),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: StatusColors.done.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: StatusColors.done, width: 2),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.mark_email_read, color: StatusColors.done),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Intervention terminée · Rapport envoyé au client',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Voir le rapport'),
                onPressed: () => _openReport(i),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final Widget child;

  const _Step({required this.number, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: primary,
                    child: Text('$number',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: StatusColors.onSite),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  final List<String> photos;
  final bool readOnly;
  final VoidCallback onCamera;
  final VoidCallback onExample;
  final ValueChanged<String> onRemove;

  const _PhotoSection({
    required this.photos,
    required this.readOnly,
    required this.onCamera,
    required this.onExample,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (photos.isEmpty && readOnly) const Text('Aucune photo'),
        if (photos.isNotEmpty)
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, k) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(width: 140, height: 110, child: PhotoView(path: photos[k])),
                  ),
                  if (!readOnly)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                        iconSize: 18,
                        icon: const Icon(Icons.close),
                        onPressed: () => onRemove(photos[k]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (!readOnly) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text("Utiliser une photo d'exemple"),
            onPressed: onExample,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.photo_camera),
            label: const Text('Prendre une photo'),
            onPressed: onCamera,
          ),
        ],
      ],
    );
  }
}
