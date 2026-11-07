
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class JanaPdf {
  static double nombor(dynamic nilai) {
    if (nilai is num) return nilai.toDouble();
    return double.tryParse(
          nilai.toString().replaceAll(',', ''),
        ) ??
        0;
  }

  static String wang(dynamic nilai) {
    final jumlah = nombor(nilai).toStringAsFixed(2);
    final bahagian = jumlah.split('.');
    final depan = bahagian[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'RM $depan.${bahagian[1]}';
  }

  static String tarikh(dynamic nilai) {
    final teks = nilai?.toString() ?? '';
    final date = DateTime.tryParse(teks);

    if (date == null) return teks;

    final hari = date.day.toString().padLeft(2, '0');
    final bulan = date.month.toString().padLeft(2, '0');

    return '$hari/$bulan/${date.year}';
  }

  static Future<void> jana(
    Map<String, dynamic> data,
  ) async {
    final pdf = pw.Document();

    final tajuk = data['tajuk']?.toString() ?? '-';
    final pelanggan =
        data['pelanggan']?.toString() ?? '-';
    final tarikhDokumen = tarikh(data['tarikh']);

    final items = data['items'] is List
        ? data['items'] as List
        : <dynamic>[];

    final List<List<String>> jadual = [];

    for (var i = 0; i < items.length; i++) {
      final rekod = items[i];

      if (rekod is! Map) continue;

      final butiran =
          rekod['butiran']?.toString() ?? '-';
      final unit = rekod['unit']?.toString() ?? '-';
      final kuantiti = nombor(rekod['kuantiti']);
      final kadar = nombor(rekod['kadar']);
      final jumlah = kuantiti * kadar;

      jadual.add([
        '${i + 1}',
        butiran,
        unit,
        kuantiti.toStringAsFixed(2),
        wang(kadar),
        wang(jumlah),
      ]);
    }

    final jumlahKeseluruhan = items.fold<double>(
      0,
      (jumlah, rekod) {
        if (rekod is! Map) return jumlah;
        return jumlah +
            nombor(rekod['kuantiti']) *
                nombor(rekod['kadar']);
      },
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'SEBUTPRO MY',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'SEBUT HARGA',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Text('Pelanggan: $pelanggan'),
          pw.Text('Tarikh: $tarikhDokumen'),
          pw.SizedBox(height: 12),
          pw.Text(
            'Tajuk Kerja: $tajuk',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              'Bil.',
              'Butiran Kerja',
              'Unit',
              'Kuantiti',
              'Kadar',
              'Jumlah',
            ],
            data: jadual,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blue900,
            ),
            cellStyle: const pw.TextStyle(
              fontSize: 8,
            ),
            cellPadding: const pw.EdgeInsets.all(5),
            columnWidths: {
              0: const pw.FixedColumnWidth(25),
              1: const pw.FlexColumnWidth(4),
              2: const pw.FixedColumnWidth(35),
              3: const pw.FixedColumnWidth(48),
              4: const pw.FixedColumnWidth(65),
              5: const pw.FixedColumnWidth(72),
            },
          ),
          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'JUMLAH KESELURUHAN: '
              '${wang(jumlahKeseluruhan)}',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ),
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.Text(
            'Dokumen dijana menggunakan SebutPro MY.',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Sebut_Harga.pdf',
    );
  }
}
