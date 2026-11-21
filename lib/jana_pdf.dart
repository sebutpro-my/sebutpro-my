
import 'dart:convert';
import 'dart:typed_data';
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

Uint8List? bacaImejProfil(String kunci) {
  final teks = profil[kunci]?.toString();

  if (teks == null || teks.isEmpty) {
    return null;
  }

  try {
    final bytes = base64Decode(teks);
    return bytes.isEmpty ? null : bytes;
  } on FormatException {
    return null;
  }
}

final logoSyarikat =
    bacaImejProfil('logo_syarikat');

final copSyarikat =
    bacaImejProfil('cop_syarikat');

    final tajuk = data['tajuk']?.toString() ?? '-';
    final rujukan = data['rujukan']?.toString() ?? '';
   
final idBqAsal =
    data['id_bq_asal']?.toString().trim() ?? '';

final tajukBqAsal =
    data['tajuk_bq_asal']?.toString().trim() ?? '';

final formatBqAsal =
    data['format_bq_asal']?.toString().trim() ?? '';

final adaBqAsal =
    idBqAsal.isNotEmpty ||
    tajukBqAsal.isNotEmpty ||
    formatBqAsal.isNotEmpty;

final labelFormatBq =
    formatBqAsal.toLowerCase() == 'jkr'
        ? 'BQ Gaya JKR'
        : formatBqAsal.toLowerCase() == 'komersial'
            ? 'BQ Komersial'
            : formatBqAsal;
    
 final pelanggan =
        data['pelanggan']?.toString() ?? '-';
 
final maklumatAsal = data['maklumat_pelanggan'];

final maklumatPelanggan = maklumatAsal is Map
    ? Map<String, dynamic>.from(maklumatAsal)
    : <String, dynamic>{};

String bacaPelanggan(String kunci) {
  return maklumatPelanggan[kunci]?.toString().trim() ?? '';
}

final syarikatPelanggan = bacaPelanggan('syarikat');
final alamatPelanggan = bacaPelanggan('alamat');
final telefonPelanggan = bacaPelanggan('telefon');
final emelPelanggan = bacaPelanggan('emel');
   
final deposit = double.tryParse(
  data['deposit']?.toString() ?? '',
);

final tempohSah =
    data['tempoh_sah']?.toString().trim() ?? '';

final termaPembayaran =
    data['terma_pembayaran']?.toString().trim() ?? '';

Uint8List? bacaTandatangan(String kunci) {
  final teks = data[kunci]?.toString();

  if (teks == null || teks.isEmpty) {
    return null;
  }

  try {
    final bytes = base64Decode(teks);
    return bytes.isEmpty ? null : bytes;
  } on FormatException {
    return null;
  }
}

final tandatanganKontraktor =
    bacaTandatangan('tandatangan_kontraktor');

final tandatanganPelanggan =
    bacaTandatangan('tandatangan_pelanggan');
final tarikhDokumen = tarikh(data['tarikh']);

    final items = data['items'] is List
        ? data['items'] as List
        : <dynamic>[];

    final List<List<String>> jadual = [];

    final Map<String, List<Map<String, dynamic>>>
        itemMengikutBahagian = {};

    final Map<String, String> namaBahagian = {};

    for (var i = 0; i < items.length; i++) {
      final rekod = items[i];

      if (rekod is! Map) continue;

      final butiran =
          rekod['butiran']?.toString() ?? '-';
      final unit = rekod['unit']?.toString() ?? '-';
      final kuantiti = nombor(rekod['kuantiti']);
      final kadar = nombor(rekod['kadar']);
      final jumlah = kuantiti * kadar;

final idBahagian =
    rekod['id_bahagian_bq']?.toString().trim() ?? '';

final namaBahagianItem =
    rekod['nama_bahagian_bq']?.toString().trim() ?? '';

final kunciBahagian = idBahagian.isNotEmpty
    ? 'id:$idBahagian'
    : namaBahagianItem.isNotEmpty
        ? 'nama:$namaBahagianItem'
        : '__tanpa_bahagian__';

itemMengikutBahagian.putIfAbsent(
  kunciBahagian,
  () => <Map<String, dynamic>>[],
);

itemMengikutBahagian[kunciBahagian]!.add({
  'bil': i + 1,
  'butiran': butiran,
  'unit': unit,
  'kuantiti': kuantiti,
  'kadar': kadar,
  'jumlah': jumlah,
});

namaBahagian.putIfAbsent(
  kunciBahagian,
  () => namaBahagianItem.isNotEmpty
      ? namaBahagianItem
      : 'LAIN-LAIN KERJA',
);

      jadual.add([
        '${i + 1}',
        butiran,
        unit,
        kuantiti.toStringAsFixed(2),
        wang(kadar),
        wang(jumlah),
      ]);
    }

final adaItemBerbahagianBq = items.any((rekod) {
  if (rekod is! Map) return false;

  final id =
      rekod['id_bahagian_bq']?.toString().trim() ?? '';

  final nama =
      rekod['nama_bahagian_bq']?.toString().trim() ?? '';

  return id.isNotEmpty || nama.isNotEmpty;
});

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

final List<pw.Widget> jadualBahagianBq = [];

if (adaItemBerbahagianBq) {
  for (final entry in itemMengikutBahagian.entries) {
    final kunci = entry.key;
    final senaraiItem = entry.value;

    if (senaraiItem.isEmpty) continue;

    final nama = namaBahagian[kunci] ?? 'LAIN-LAIN KERJA';

    double subtotal = 0;

    final baris = <List<String>>[];
    int bilBahagian = 0;

    for (final item in senaraiItem) {
      final kuantiti = (item['kuantiti'] as num).toDouble();
      final kadar = (item['kadar'] as num).toDouble();
      final jumlah = kuantiti * kadar;

      subtotal += jumlah;

      baris.add([
        '${++bilBahagian}',
        item['butiran'].toString(),
        item['unit'].toString(),
        kuantiti.toStringAsFixed(2),
        wang(kadar),
        wang(jumlah),
      ]);
    }

    jadualBahagianBq.add(
      pw.NewPage(freeSpace: 100),
    );

    jadualBahagianBq.add(
      pw.Text(
        nama.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );

    jadualBahagianBq.add(
      pw.SizedBox(height: 8),
    );

    jadualBahagianBq.add(
      pw.TableHelper.fromTextArray(
        headers: [
          'Bil.',
          'Butiran Kerja',
          'Unit',
          'Kuantiti',
          'Kadar',
          'Jumlah',
        ],
        data: baris,
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
        columnWidths: {
          0: const pw.FixedColumnWidth(25),
          1: const pw.FlexColumnWidth(4),
          2: const pw.FixedColumnWidth(35),
          3: const pw.FixedColumnWidth(48),
          4: const pw.FixedColumnWidth(65),
          5: const pw.FixedColumnWidth(72),
        },
      ),
    );

    jadualBahagianBq.add(
      pw.SizedBox(height: 6),
    );

    jadualBahagianBq.add(
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'SUBTOTAL $nama: ${wang(subtotal)}',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );

    jadualBahagianBq.add(
      pw.SizedBox(height: 18),
    );
  }
}

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          
pw.Center(
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      
if (logoSyarikat != null) ...[
  pw.Image(
    pw.MemoryImage(logoSyarikat),
    height: 55,
    width: 110,
    fit: pw.BoxFit.contain,
  ),
  pw.SizedBox(height: 8),
],
      
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
          
pw.SizedBox(height: 8),

pw.Text(
  'MAKLUMAT PELANGGAN / BILL TO',
  style: pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
  ),
),

pw.SizedBox(height: 5),

pw.Text('Nama Pelanggan: $pelanggan'),

if (syarikatPelanggan.isNotEmpty)
  pw.Text('Syarikat: $syarikatPelanggan'),

if (alamatPelanggan.isNotEmpty)
  pw.Text('Alamat: $alamatPelanggan'),

if (telefonPelanggan.isNotEmpty)
  pw.Text('Telefon: $telefonPelanggan'),

if (emelPelanggan.isNotEmpty)
  pw.Text('E-mel: $emelPelanggan'),

          pw.Text('Tarikh: $tarikhDokumen'),
          pw.SizedBox(height: 12),
          pw.Text(
            'Tajuk Kerja: $tajuk',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ),
          ),
         
if (adaBqAsal) ...[
  pw.SizedBox(height: 10),
  pw.Text(
    'MAKLUMAT BQ ASAL',
    style: pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    ),
  ),
  pw.SizedBox(height: 5),

  if (tajukBqAsal.isNotEmpty)
    pw.Text('Tajuk BQ: $tajukBqAsal'),

  if (labelFormatBq.isNotEmpty)
    pw.Text('Format BQ: $labelFormatBq'),

  if (idBqAsal.isNotEmpty)
    pw.Text('ID BQ: $idBqAsal'),
],
 pw.SizedBox(height: 20),
   
if (adaItemBerbahagianBq) ...jadualBahagianBq,
if (!adaItemBerbahagianBq)
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

if (tandatanganKontraktor != null ||
    tandatanganPelanggan != null ||
    copSyarikat != null)

  pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'TANDATANGAN',
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Row(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              children: [
                if (tandatanganKontraktor != null)
                  pw.Image(
                    pw.MemoryImage(
                      tandatanganKontraktor,
                    ),
                    height: 65,
                    fit: pw.BoxFit.contain,
                  )
                else
                  pw.SizedBox(height: 65),
                
if (copSyarikat != null) ...[
  pw.SizedBox(height: 6),
  pw.Image(
    pw.MemoryImage(copSyarikat),
    height: 55,
    width: 100,
    fit: pw.BoxFit.contain,
  ),
],
                
pw.SizedBox(height: 8),
                pw.Divider(),
                pw.Text(
                  'Tandatangan Kontraktor',
                  style: const pw.TextStyle(
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 24),
          pw.Expanded(
            child: pw.Column(
              children: [
                if (tandatanganPelanggan != null)
                  pw.Image(
                    pw.MemoryImage(
                      tandatanganPelanggan,
                    ),
                    height: 65,
                    fit: pw.BoxFit.contain,
                  )
                else
                  pw.SizedBox(height: 65),
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.Text(
                  'Tandatangan Pelanggan',
                  style: const pw.TextStyle(
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 16),
    ],
  ),

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
