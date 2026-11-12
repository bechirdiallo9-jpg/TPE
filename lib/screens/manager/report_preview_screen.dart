import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../services/pdf_report.dart';
import '../../state/demo_store.dart';

class ReportPreviewScreen extends StatefulWidget {
  final String interventionId;

  const ReportPreviewScreen({super.key, required this.interventionId});

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  late final Future<Uint8List> _pdf;
  late final String _fileName;

  @override
  void initState() {
    super.initState();
    final store = context.read<DemoStore>();
    final i = store.interventionById(widget.interventionId);
    final client = store.siteById(i.siteId).clientName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-');
    _fileName = 'rapport-intervention-$client.pdf';
    _pdf = PdfReport.build(store, i); // généré une seule fois
  }

  Future<void> _share() async {
    final bytes = await _pdf;
    await Printing.sharePdf(bytes: bytes, filename: _fileName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rapport client')),
      body: PdfPreview(
        build: (_) => _pdf,
        pdfFileName: _fileName,
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        onError: (_, _) => const Center(
          child: Text("Impossible d'afficher le rapport", style: TextStyle(fontSize: 18)),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Partager'),
            onPressed: _share,
          ),
        ),
      ),
    );
  }
}
