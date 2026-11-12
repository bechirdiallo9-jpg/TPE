import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/intervention.dart';
import '../state/demo_store.dart';

/// Génère le rapport client A4. Les photos sont déjà réduites à la prise
/// (1024 px max) et les photos d'exemple font 800 px : le PDF reste léger.
class PdfReport {
  static Future<Uint8List> build(DemoStore store, Intervention i) async {
    final site = store.siteById(i.siteId);
    final agent = store.agentById(i.agentId);
    final primary = PdfColor.fromInt(store.config.colorValue);
    const green = PdfColor.fromInt(0xFF2E7D32);
    const grey = PdfColor.fromInt(0xFF6B7280);
    final hm = DateFormat.Hm('fr_FR');

    final logo = pw.MemoryImage(await _bytes(store.config.logoPath ?? 'assets/logo_default.png'));
    final before = [for (final p in i.photosBefore) pw.MemoryImage(await _bytes(p))];
    final after = [for (final p in i.photosAfter) pw.MemoryImage(await _bytes(p))];
    final pairs = before.length > after.length ? before.length : after.length;

    final day = toBeginningOfSentenceCase(
        DateFormat('EEEE d MMMM y', 'fr_FR').format(i.arrivedAt ?? i.plannedStart));
    final onSite = i.timeOnSite;
    String duration(Duration d) =>
        d.inHours > 0 ? '${d.inHours} h ${(d.inMinutes % 60).toString().padLeft(2, '0')}' : '${d.inMinutes} min';

    pw.Widget infoRow(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.SizedBox(width: 110, child: pw.Text(label, style: const pw.TextStyle(color: grey))),
            pw.Expanded(child: pw.Text(_safe(value), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          ]),
        );

    pw.Widget sectionTitle(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
          child: pw.Text(t, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primary)),
        );

    pw.Widget photo(pw.MemoryImage? img, String label) => pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: grey)),
            pw.SizedBox(height: 4),
            pw.Container(
              height: 170,
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF1F3F5),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: img == null
                  ? pw.Center(child: pw.Text('-', style: const pw.TextStyle(color: grey)))
                  : pw.ClipRRect(
                      horizontalRadius: 6,
                      verticalRadius: 6,
                      child: pw.Image(img, fit: pw.BoxFit.cover, height: 170),
                    ),
            ),
          ]),
        );

    final doc = pw.Document(title: "Rapport d'intervention", author: _safe(store.companyName));
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
      theme: pw.ThemeData.withFont(base: pw.Font.helvetica(), bold: pw.Font.helveticaBold())
          .copyWith(defaultTextStyle: const pw.TextStyle(fontSize: 11)),
      header: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 12),
        margin: const pw.EdgeInsets.only(bottom: 16),
        decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: primary, width: 2))),
        child: pw.Row(children: [
          pw.SizedBox(width: 48, height: 48, child: pw.Image(logo, fit: pw.BoxFit.contain)),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(_safe(store.companyName),
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text("Rapport d'intervention",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: primary)),
        ]),
      ),
      footer: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 8),
        decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColor.fromInt(0xFFDDE1E6)))),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text("Rapport généré automatiquement à la fin de l'intervention.",
              style: const pw.TextStyle(fontSize: 9, color: grey)),
          pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: grey)),
        ]),
      ),
      build: (ctx) => [
        infoRow('Client', site.clientName),
        infoRow('Adresse', site.fullAddress),
        infoRow('Date', day),
        infoRow('Intervenant', agent.displayName),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF5F7FA),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
            _bigValue('Arrivée', i.arrivedAt == null ? '-' : hm.format(i.arrivedAt!)),
            _bigValue('Départ', i.leftAt == null ? '-' : hm.format(i.leftAt!)),
            _bigValue('Durée sur site', onSite == null ? '-' : duration(onSite)),
          ]),
        ),
        sectionTitle('Prestations réalisées'),
        for (final t in i.tasks)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Row(children: [
              pw.Container(
                width: 14,
                height: 14,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: t.done ? green : null,
                  border: pw.Border.all(color: t.done ? green : grey, width: 1.2),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: t.done
                    ? pw.SvgImage(svg: _checkSvg, width: 10, height: 10)
                    : null,
              ),
              pw.SizedBox(width: 8),
              pw.Text(_safe(t.label), style: t.done ? null : const pw.TextStyle(color: grey)),
            ]),
          ),
        if (pairs > 0) sectionTitle('Photos avant / après'),
        for (var k = 0; k < pairs; k++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              photo(k < before.length ? before[k] : null, 'AVANT'),
              pw.SizedBox(width: 10),
              photo(k < after.length ? after[k] : null, 'APRÈS'),
            ]),
          ),
        if (i.comment.trim().isNotEmpty) ...[
          sectionTitle("Commentaire de l'intervenant"),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide(color: primary, width: 3)),
              color: const PdfColor.fromInt(0xFFF5F7FA),
            ),
            child: pw.Row(children: [pw.Expanded(child: pw.Text(_safe(i.comment.trim())))]),
          ),
        ],
      ],
    ));
    return doc.save();
  }

  // Coche dessinée : rendu identique quel que soit le lecteur PDF.
  static const _checkSvg = '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M4 12.5l5 5L20 6.5" fill="none" stroke="#ffffff" stroke-width="3.5" '
      'stroke-linecap="round" stroke-linejoin="round"/></svg>';

  static pw.Widget _bigValue(String label, String value) => pw.Column(children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF6B7280))),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ]);

  static Future<Uint8List> _bytes(String path) async {
    if (path.startsWith('assets/')) {
      return (await rootBundle.load(path)).buffer.asUint8List();
    }
    return File(path).readAsBytes();
  }

  /// Les polices PDF standard ne couvrent que le latin de base : on remplace
  /// la typographie du clavier (apostrophe ’, tirets, œ...) et les émojis.
  static String _safe(String s) {
    const map = {
      '’': "'", '‘': "'", '“': '"', '”': '"', '–': '-', '—': '-', '…': '...',
      'œ': 'oe', 'Œ': 'OE', '€': 'EUR', '\u202F': ' ', '\u2009': ' ',
    };
    final out = StringBuffer();
    for (final r in s.runes) {
      final c = String.fromCharCode(r);
      if (map.containsKey(c)) {
        out.write(map[c]);
      } else if ((r >= 32 && r < 127) || (r >= 160 && r <= 255) || r == 10) {
        out.write(c);
      }
    }
    return out.toString();
  }
}
