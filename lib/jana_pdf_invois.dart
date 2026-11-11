
import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JanaPdfInvois {
  static double nombor(dynamic nilai) {
    if (nilai is num) return nilai.toDouble();

    return double.tryParse(
          nilai.toString().replaceAll(',', '').trim(),
        ) ??
        0;
  }

  static String wang(dynamic nilai) {
    final bahagian = nombor(nilai).toStringAsFixed(2).split('.');

    final depan = bahagian[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return 'RM $depan.${bahagian[1]}';
  }

  static String tarikh(dynamic nilai) {
    final asal = DateTime.tryParse(nilai?.toString() ?? '');

    if (asal == null) return '-';

    final hari = asal.day.toString().padLeft(2, '0');
    final bulan = asal.month.toString().padLeft(2, '0');

    return '$hari/$bulan/${asal.year}';
  }

  static Future<void> jana(
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final teksProfil = prefs.getString('profil_syarikat');
    final Map<String, dynamic> profil = {};

    if (teksProfil != null) {
      final hasil = jsonDecode(teksProfil);
      if (hasil is Map) {
        profil.addAll(Map<String, dynamic>.from(hasil));
      }
    }

    String baca(String kunci) =>
        profil[kunci]?.toString().trim() ?? '';

    Uint8List? bacaLogo() {
      final teks = baca('logo_syarikat');
      if (teks.isEmpty) return null;

      try {
        final bytes = base64Decode(teks);
        return bytes.isEmpty ? null : bytes;
      } catch (_) {
        return null;
      }
    }

    final logo = bacaLogo();

    final itemAsal = data['items'];
    final items = itemAsal is List ? itemAsal : [];

    final baris = <List<String>>[];

    for (int i = 0; i < items.length; i++) {
      final rekod = items[i];
      if (rekod is! Map) continue;

      final qty = nombor(rekod['kuantiti']);
      final kadar = nombor(rekod['kadar']);

      baris.add([
        '${baris.length + 1}',
        rekod['butiran']?.toString() ?? '',
        '${rekod['kuantiti'] ?? ''}',
        rekod['unit']?.toString() ?? '',
        wang(kadar),
        wang(qty * kadar),
      ]);
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      baca('nama').isEmpty
                          ? 'NAMA SYARIKAT'
                          : baca('nama'),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (baca('ssm').isNotEmpty)
                      pw.Text('No. SSM: ${baca('ssm')}'),
                    if (baca('alamat').isNotEmpty)
                      pw.Text(baca('alamat')),
                    if (baca('telefon').isNotEmpty)
                      pw.Text('Tel: ${baca('telefon')}'),
                    if (baca('emel').isNotEmpty)
                      pw.Text('E-mel: ${baca('emel')}'),
                  ],
                ),
              ),
              if (logo != null)
                pw.SizedBox(
                  width: 85,
                  height: 65,
                  child: pw.Image(
                    pw.MemoryImage(logo),
                    fit: pw.BoxFit.contain,
                  ),
                ),
            ],
          ),

          pw.SizedBox(height: 20),
          pw.Divider(),

          pw.Center(
            child: pw.Text(
              'INVOIS',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(height: 18),

          pw.Text(
            'No. Invois: ${data['nombor_invois'] ?? '-'}',
          ),
          pw.Text(
            'Tarikh: ${tarikh(data['tarikh'])}',
          ),
          pw.Text(
            'Pelanggan: ${data['pelanggan'] ?? '-'}',
          ),
          pw.Text(
            'Tajuk Kerja: ${data['tajuk'] ?? '-'}',
          ),
          pw.Text(
            'Status: ${data['status'] ?? 'Belum Bayar'}',
          ),

          pw.SizedBox(height: 18),

          pw.Table.fromTextArray(
            headers: const [
              'Bil.',
              'Butiran Kerja',
              'Kuantiti',
              'Unit',
              'Kadar',
              'Jumlah',
            ],
            data: baris,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            cellPadding: const pw.EdgeInsets.all(5),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.5),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(0.9),
              3: const pw.FlexColumnWidth(0.8),
              4: const pw.FlexColumnWidth(1.3),
              5: const pw.FlexColumnWidth(1.5),
            },
          ),

          pw.SizedBox(height: 16),

          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'JUMLAH KESELURUHAN: '
              '${wang(data['jumlah'])}',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(height: 25),

          if (baca('bank').isNotEmpty ||
              baca('pemegangAkaun').isNotEmpty ||
              baca('nomborAkaun').isNotEmpty) ...[
            pw.Text(
              'MAKLUMAT PEMBAYARAN',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 7),
            if (baca('bank').isNotEmpty)
              pw.Text('Bank: ${baca('bank')}'),
            if (baca('pemegangAkaun').isNotEmpty)
              pw.Text(
                'Nama Akaun: ${baca('pemegangAkaun')}',
              ),
            if (baca('nomborAkaun').isNotEmpty)
              pw.Text(
                'No. Akaun: ${baca('nomborAkaun')}',
              ),
          ],

          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.Text(
            'Dokumen dijana menggunakan SebutPro MY',
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
      name: 'Invois.pdf',
    );
  }
}
