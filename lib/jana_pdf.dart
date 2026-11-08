
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
    
final prefs = await SharedPreferences.getInstance();
final teksProfil = prefs.getString('profil_syarikat');

final Map<String, dynamic> profil = {};

if (teksProfil != null) {
  final hasil = jsonDecode(teksProfil);
  if (hasil is Map) {
    profil.addAll(Map<String, dynamic>.from(hasil));
  }
}

final namaSyarikat =
    profil['nama']?.toString() ?? '';
final ssmSyarikat =
    profil['ssm']?.toString() ?? '';
final alamatSyarikat =
    profil['alamat']?.toString() ?? '';
final telefonSyarikat =
    profil['telefon']?.toString() ?? '';
final emelSyarikat =
    profil['emel']?.toString() ?? '';

final namaBank =
    profil['bank']?.toString().trim() ?? '';
final pemegangAkaun =
    profil['pemegangAkaun']?.toString().trim() ?? '';
final nomborAkaun =
    profil['nomborAkaun']?.toString().trim() ?? '';

final adaMaklumatBank =
    namaBank.isNotEmpty ||
    pemegangAkaun.isNotEmpty ||
    nomborAkaun.isNotEmpty;

    final tajuk = data['tajuk']?.toString() ?? '-';
    final rujukan = data['rujukan']?.toString() ?? '';
    final pelanggan =
        data['pelanggan']?.toString() ?? '-';
    
final deposit = double.tryParse(
  data['deposit']?.toString() ?? '',
);

final tempohSah =
    data['tempoh_sah']?.toString().trim() ?? '';

final termaPembayaran =
    data['terma_pembayaran']?.toString().trim() ?? '';
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

    final amaunDeposit = deposit != null
        ? jumlahKeseluruhan * deposit / 100
        : null;

    final bakiPembayaran = amaunDeposit != null
        ? jumlahKeseluruhan - amaunDeposit
        : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          
pw.Center(
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Text(
        namaSyarikat.isNotEmpty
            ? namaSyarikat
            : 'NAMA SYARIKAT BELUM DIISI',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
      if (ssmSyarikat.isNotEmpty)
        pw.Text(
          'No. SSM: $ssmSyarikat',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 9),
        ),
      if (alamatSyarikat.isNotEmpty)
        pw.Text(
          alamatSyarikat,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 9),
        ),
      if (telefonSyarikat.isNotEmpty)
        pw.Text(
          'Tel: $telefonSyarikat',
          style: const pw.TextStyle(fontSize: 9),
        ),
      if (emelSyarikat.isNotEmpty)
        pw.Text(
          'E-mel: $emelSyarikat',
          style: const pw.TextStyle(fontSize: 9),
        ),
      pw.SizedBox(height: 14),
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

          pw.Divider(),
          
if (rujukan.isNotEmpty)
          pw.Text('No. Rujukan: $rujukan'),
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
          pw.TableHelper.fromTextArray(
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
          
pw.SizedBox(height: 24),

if (deposit != null ||
    tempohSah.isNotEmpty ||
    termaPembayaran.isNotEmpty)
  pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'TERMA & SYARAT SEBUT HARGA',
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
      pw.SizedBox(height: 8),

      if (deposit != null && amaunDeposit != null)
        pw.Text(
          'Deposit (${deposit.toStringAsFixed(0)}%): '
          '${wang(amaunDeposit)}',
        ),

      if (bakiPembayaran != null)
        pw.Text(
          'Baki Pembayaran: ${wang(bakiPembayaran)}',
        ),

      if (tempohSah.isNotEmpty)
        pw.Text(
          'Tempoh Sah Tawaran: $tempohSah hari',
        ),

      if (termaPembayaran.isNotEmpty) ...[
        pw.SizedBox(height: 8),
        pw.Text(
          termaPembayaran,
        ),
      ],

      pw.SizedBox(height: 16),
    ],
  ),

if (adaMaklumatBank)
  pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'MAKLUMAT PEMBAYARAN',
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
      pw.SizedBox(height: 8),
      if (namaBank.isNotEmpty)
        pw.Text(
          'Nama Bank: $namaBank',
          style: const pw.TextStyle(fontSize: 9),
        ),
      if (pemegangAkaun.isNotEmpty)
        pw.Text(
          'Pemegang Akaun: $pemegangAkaun',
          style: const pw.TextStyle(fontSize: 9),
        ),
      if (nomborAkaun.isNotEmpty)
        pw.Text(
          'No. Akaun: $nomborAkaun',
          style: const pw.TextStyle(fontSize: 9),
        ),
    ],
  ),

pw.SizedBox(height: 24),

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
