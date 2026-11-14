
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
      pw.Text(
        tajuk.isEmpty ? 'TANPA TAJUK' : tajuk,
        textAlign: pw.TextAlign.center,
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
      pw.Text(
        gayaJkr
            ? 'FORMAT BQ GAYA JKR'
            : 'FORMAT BQ KOMERSIAL',
        style: const pw.TextStyle(
          fontSize: 9,
          color: PdfColors.grey700,
        ),
      ),
    );

    kandungan.add(
      pw.SizedBox(height: 18),
    );

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
          headers: const [
            'Bil.',
            'Butiran Kerja',
            'Unit',
            'Kuantiti',
            'Kadar (RM)',
            'Jumlah (RM)',
          ],
          data: baris,
          headerStyle: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: const pw.TextStyle(
            fontSize: 8,
          ),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          border: pw.TableBorder.all(
            color: PdfColors.grey600,
            width: 0.5,
          ),
          cellPadding: const pw.EdgeInsets.all(5),
          columnWidths: {
            0: const pw.FlexColumnWidth(0.7),
            1: const pw.FlexColumnWidth(3.5),
            2: const pw.FlexColumnWidth(0.8),
            3: const pw.FlexColumnWidth(0.9),
            4: const pw.FlexColumnWidth(1.3),
            5: const pw.FlexColumnWidth(1.4),
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
            'Muka Surat ${context.pageNumber}',
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
