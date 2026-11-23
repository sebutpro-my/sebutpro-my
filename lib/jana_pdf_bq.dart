
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class JanaPdfBq {
  static double nombor(dynamic nilai) {
    if (nilai is num) return nilai.toDouble();

    return double.tryParse(
          nilai.toString().replaceAll(',', ''),
        ) ??
        0;
  }

  static String wang(dynamic nilai) {
    final pecahan = nombor(nilai)
        .toStringAsFixed(2)
        .split('.');

    final depan = pecahan[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (padanan) => ',',
    );

    return '$depan.${pecahan[1]}';
  }

  static String kodBahagian(int nombor) {
    var nilai = nombor;
    var kod = '';

    do {
      kod = String.fromCharCode(
            65 + (nilai % 26),
          ) +
          kod;

      nilai = nilai ~/ 26 - 1;
    } while (nilai >= 0);

    return kod;
  }

  static double jumlahItem(
    Map<String, dynamic> item,
  ) {
    return nombor(item['kuantiti']) *
        nombor(item['kadar']);
  }

  static Future<void> jana(
    Map<String, dynamic> rekod,
  ) async {
    final pdf = pw.Document();

final prefs = await SharedPreferences.getInstance();
final teksProfil = prefs.getString('profil_syarikat');
final Map<String, dynamic> profil = {};

if (teksProfil != null) {
  try {
    final hasil = jsonDecode(teksProfil);
    if (hasil is Map) {
      profil.addAll(Map<String, dynamic>.from(hasil));
    }
  } catch (_) {}
}

String baca(String kunci) {
  return profil[kunci]?.toString().trim() ?? '';
}

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

    final format = rekod['format']
            ?.toString()
            .toLowerCase() ??
        '';

    final gayaJkr = format.contains('jkr');

    final tajuk = rekod['tajuk']
            ?.toString()
            .trim() ??
        '';

    final dataAsal = rekod['bahagian'];

    final bahagian = <Map<String, dynamic>>[];

    if (dataAsal is List) {
      for (final data in dataAsal) {
        if (data is Map) {
          bahagian.add(
            Map<String, dynamic>.from(data),
          );
        }
      }
    }

    final kandungan = <pw.Widget>[];

kandungan.add(
  pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              baca('nama').isEmpty
                  ? 'NAMA SYARIKAT'
                  : baca('nama'),
              style: pw.TextStyle(
                color: PdfColors.blue900,
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
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
);

kandungan.add(
  pw.SizedBox(height: 12),
);

kandungan.add(
  pw.Divider(
    color: PdfColors.grey600,
    thickness: 0.8,
  ),
);

kandungan.add(
  pw.SizedBox(height: 16),
);

    double jumlahKeseluruhan = 0;

    kandungan.add(
      pw.Center(
        child: pw.Text(
          gayaJkr
              ? 'SENARAI KUANTITI KERJA'
              : 'BILL OF QUANTITIES',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );

    kandungan.add(
      pw.SizedBox(height: 14),
    );
 
kandungan.add(
  gayaJkr
      ? pw.Center(
          child: pw.Text(
            tajuk.isEmpty ? 'TANPA TAJUK' : tajuk,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        )
      : pw.Text(
          tajuk.isEmpty ? 'TANPA TAJUK' : tajuk,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
);

    kandungan.add(
      pw.SizedBox(height: 12),
    );

kandungan.add(
  gayaJkr
      ? pw.Center(
          child: pw.Text(
            'FORMAT BQ GAYA JKR',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        )
      : pw.Text(
          'FORMAT BQ KOMERSIAL',
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
);

    kandungan.add(    
      pw.SizedBox(height: gayaJkr ? 10 : 18),

    );

if (gayaJkr) {
} else {
  kandungan.add(
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blueGrey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RINGKASAN KERJA',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Senarai kerja, kuantiti, kadar '
            'dan harga mengikut bahagian.',
            style: const pw.TextStyle(
              fontSize: 9,
            ),
          ),
        ],
      ),
    ),
  );
}

kandungan.add(
  pw.SizedBox(height: 18),
);

final ringkasanHarga = <List<String>>[];

    for (int i = 0; i < bahagian.length; i++) {
      final data = bahagian[i];
      final kod = kodBahagian(i);

      final nama = data['nama']
              ?.toString()
              .trim() ??
          '';

      final itemAsal = data['items'];
      final items = <Map<String, dynamic>>[];

      if (itemAsal is List) {
        for (final item in itemAsal) {
          if (item is Map) {
            items.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      double jumlahBahagian = 0;

      final baris = <List<String>>[];

      for (int j = 0; j < items.length; j++) {
        final item = items[j];
        final jumlah = jumlahItem(item);

        jumlahBahagian += jumlah;

        baris.add([
          gayaJkr
              ? '$kod${j + 1}'
              : '${j + 1}',
          item['butiran']?.toString() ?? '',
          item['unit']?.toString() ?? '',
          item['kuantiti']?.toString() ?? '',
          wang(item['kadar']),
          wang(jumlah),
        ]);
      }

      jumlahKeseluruhan += jumlahBahagian;

ringkasanHarga.add([
  kod,
  nama,
  wang(jumlahBahagian),
]);

kandungan.add(
  pw.NewPage(freeSpace: 140),
);

      kandungan.add(
        pw.Text(
          '$kod - $nama',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );

      kandungan.add(
        pw.SizedBox(height: 8),
      );

kandungan.add(
  pw.Table.fromTextArray(
    headers: gayaJkr
        ? [
            'Bil.',
            'Butiran Kerja',
            'Unit',
            'Kuantiti',
            'Kadar (RM)',
            'Jumlah (RM)',
          ]
        : [
            'No.',
            'Kerja / Perkhidmatan',
            'Unit',
            'Kuantiti',
            'Harga Unit (RM)',
            'Jumlah (RM)',
          ],
    data: baris,
    headerStyle: pw.TextStyle(
      fontSize: gayaJkr ? 8 : 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    ),
    cellStyle: pw.TextStyle(
      fontSize: gayaJkr ? 8 : 9,
    ),
    headerDecoration: pw.BoxDecoration(
      color: PdfColors.blue900,
    ),
    border: pw.TableBorder.all(
      color: gayaJkr
          ? PdfColors.grey600
          : PdfColors.blueGrey200,
      width: gayaJkr ? 0.5 : 0.3,
    ),
    cellPadding: pw.EdgeInsets.symmetric(
      horizontal: gayaJkr ? 5 : 7,
      vertical: gayaJkr ? 5 : 8,
    ),
    columnWidths: {
      0: const pw.FlexColumnWidth(0.7),
      1: pw.FlexColumnWidth(gayaJkr ? 4.0 : 3.5),
      2: const pw.FlexColumnWidth(0.8),
      3: const pw.FlexColumnWidth(1.0),
      4: const pw.FlexColumnWidth(1.4),
      5: const pw.FlexColumnWidth(1.5),
    },
  ),
);

      kandungan.add(
        pw.SizedBox(height: 7),
      );

      kandungan.add(
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'JUMLAH BAHAGIAN $kod: '
            'RM ${wang(jumlahBahagian)}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      );

      kandungan.add(
        pw.SizedBox(height: 22),
      );
    }

if (gayaJkr && ringkasanHarga.isNotEmpty) {
  kandungan.add(
    pw.SizedBox(height: 12),
  );

  kandungan.add(
    pw.Center(
      child: pw.Text(
        'RINGKASAN HARGA',
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ),
  );

  kandungan.add(
    pw.SizedBox(height: 12),
  );

  kandungan.add(
    pw.Table.fromTextArray(
      headers: [
        'Bahagian',
        'Butiran Kerja',
        'Jumlah (RM)',
      ],
      data: ringkasanHarga,
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.grey300,
      ),
      border: pw.TableBorder.all(
        color: PdfColors.grey600,
        width: 0.5,
      ),
      cellPadding: const pw.EdgeInsets.all(7),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FlexColumnWidth(2),
      },
      cellAlignments: {
        2: pw.Alignment.centerRight,
      },
    ),
  );

  kandungan.add(
    pw.SizedBox(height: 14),
  );
}

    kandungan.add(
      pw.Divider(thickness: 1),
    );

    kandungan.add(
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'JUMLAH KESELURUHAN: '
          'RM ${wang(jumlahKeseluruhan)}',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => kandungan,
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
          'Muka Surat ${context.pageNumber} daripada ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
        ),
      ),
    );

    final Uint8List dataPdf = await pdf.save();

    await Printing.layoutPdf(
      onLayout: (format) async => dataPdf,
      name: gayaJkr
          ? 'BQ_Gaya_JKR.pdf'
          : 'BQ_Komersial.pdf',
    );
  }
}
