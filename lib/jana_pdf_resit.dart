
import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JanaPdfResit {
  static double nombor(dynamic nilai) {
    if (nilai is num) return nilai.toDouble();

    return double.tryParse(
          nilai.toString().replaceAll(',', '').trim(),
        ) ??
        0;
  }

  static String wang(dynamic nilai) {
    final bahagian =
        nombor(nilai).toStringAsFixed(2).split('.');

    final depan = bahagian[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return 'RM $depan.${bahagian[1]}';
  }

  static String tarikh(dynamic nilai) {
    final asal = DateTime.tryParse(
      nilai?.toString() ?? '',
    );

    if (asal == null) return '-';

    final hari = asal.day.toString().padLeft(2, '0');
    final bulan = asal.month.toString().padLeft(2, '0');

    return '$hari/$bulan/${asal.year}';
  }

  static Future<void> jana(
    Map<String, dynamic> invois,
    Map<String, dynamic> bayaran,
  ) async {
    final idInvois = invois['id']?.toString() ?? '';
    final idBayaran = bayaran['id']?.toString() ?? '';

    if (idInvois.isEmpty || idBayaran.isEmpty) {
      throw StateError('ID invois atau bayaran tidak sah.');
    }

    final transaksi = invois['rekod_bayaran'];

    if (transaksi is! List ||
        !transaksi.any(
          (item) =>
              item is Map &&
              item['id']?.toString() == idBayaran,
        )) {
      throw StateError(
        'Transaksi tidak dijumpai dalam invois.',
      );
    }

    final jumlahBayaran = nombor(bayaran['jumlah']);

    if (!jumlahBayaran.isFinite ||
        jumlahBayaran <= 0) {
      throw StateError('Jumlah bayaran tidak sah.');
    }

    final prefs =
        await SharedPreferences.getInstance();

    final teksProfil =
        prefs.getString('profil_syarikat');

    final Map<String, dynamic> profil = {};

    if (teksProfil != null) {
      final hasil = jsonDecode(teksProfil);

      if (hasil is Map) {
        profil.addAll(
          Map<String, dynamic>.from(hasil),
        );
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
    final noResit = 'RCP-$idBayaran';

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        build: (context) => [
          pw.Row(
            crossAxisAlignment:
                pw.CrossAxisAlignment.start,
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
                      pw.Text(
                        'No. SSM: ${baca('ssm')}',
                      ),
                    if (baca('alamat').isNotEmpty)
                      pw.Text(baca('alamat')),
                    if (baca('telefon').isNotEmpty)
                      pw.Text(
                        'Tel: ${baca('telefon')}',
                      ),
                    if (baca('emel').isNotEmpty)
                      pw.Text(
                        'E-mel: ${baca('emel')}',
                      ),
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
              'RESIT PEMBAYARAN',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(height: 20),

          pw.Text('No. Resit: $noResit'),

          pw.Text(
            'Tarikh Bayaran: '
            '${tarikh(bayaran['tarikh'])}',
          ),

          pw.Text(
            'No. Invois: '
            '${invois['nombor_invois'] ?? '-'}',
          ),

          pw.Text(
            'Pelanggan: '
            '${invois['pelanggan'] ?? '-'}',
          ),

          pw.Text(
            'Tajuk Kerja: '
            '${invois['tajuk'] ?? '-'}',
          ),

          pw.SizedBox(height: 25),

          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey200,
            ),
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'JUMLAH BAYARAN DITERIMA',
                  style: const pw.TextStyle(
                    fontSize: 11,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  wang(jumlahBayaran),
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          pw.Text(
            'Kaedah Pembayaran: '
            '${bayaran['kaedah'] ?? '-'}',
          ),

          pw.Text(
            'No. Rujukan Transaksi: '
            '${(bayaran['rujukan']?.toString().trim().isNotEmpty ?? false) ? bayaran['rujukan'] : '-'}',
          ),

          if ((bayaran['catatan']
                      ?.toString()
                      .trim()
                      .isNotEmpty ??
                  false)) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Catatan: ${bayaran['catatan']}',
            ),
          ],

          pw.SizedBox(height: 25),
          pw.Divider(),

          pw.Text(
            'Resit ini merujuk kepada transaksi '
            'pembayaran yang direkodkan dalam '
            'SebutPro MY.',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),

          pw.SizedBox(height: 8),

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
      name: '$noResit.pdf',
    );
  }
}
