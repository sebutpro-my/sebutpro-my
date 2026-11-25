
import 'dart:convert';

import 'backup_download_stub.dart'
    if (dart.library.html) 'backup_download_web.dart';
import 'backup_picker_stub.dart'
    if (dart.library.html) 'backup_picker_web.dart';
import 'backup_restore_service.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() =>
      _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  static const List<String> kunciUtama = [
    'profil_syarikat',
    'senarai_pelanggan',
    'senarai_bq',
    'senarai_sebut_harga',
    'senarai_invois',
    'rujukan_mod',
    'rujukan_awalan',
  ];

  bool sedangMuat = true;
  bool sedangBackup = false;
  int jumlahDikesan = 0;
  String? ralat;

  @override
  void initState() {
    super.initState();
    semakData();
  }

  Future<void> semakData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final semuaKunci = prefs.getKeys();

      if (!mounted) return;

      setState(() {
        jumlahDikesan = kunciUtama
            .where((kunci) => semuaKunci.contains(kunci))
            .length;
        sedangMuat = false;
        ralat = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        sedangMuat = false;
        ralat = 'Gagal membaca maklumat simpanan.';
      });
    }
  }

  Map<String, dynamic> bungkusNilai(Object nilai) {
    if (nilai is List<String>) {
      return {
        'jenis': 'stringList',
        'nilai': nilai,
      };
    }

    if (nilai is String) {
      return {
        'jenis': 'string',
        'nilai': nilai,
      };
    }

    if (nilai is bool) {
      return {
        'jenis': 'bool',
        'nilai': nilai,
      };
    }

    if (nilai is int) {
      return {
        'jenis': 'int',
        'nilai': nilai,
      };
    }

    if (nilai is double) {
      return {
        'jenis': 'double',
        'nilai': nilai,
      };
    }

    throw FormatException(
      'Jenis data tidak disokong: ${nilai.runtimeType}',
    );
  }

  Future<void> buatBackup() async {
    if (sedangBackup) return;

    setState(() {
      sedangBackup = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final semuaKunci = prefs.getKeys().toList()..sort();

      final Map<String, dynamic> dataBackup = {};

      for (final kunci in semuaKunci) {
        final nilai = prefs.get(kunci);

        if (nilai != null) {
          dataBackup[kunci] = bungkusNilai(nilai);
        }
      }

      for (final kunci in kunciUtama) {
        if (!dataBackup.containsKey(kunci)) {
          throw StateError(
            'Data utama tidak ditemui: $kunci',
          );
        }
      }

      final sekarang = DateTime.now();

      final kandungan = {
        'aplikasi': 'SebutPro MY',
        'versi_backup': 1,
        'tarikh_backup': sekarang.toIso8601String(),
        'jumlah_kunci': dataBackup.length,
        'data': dataBackup,
      };

      const encoder = JsonEncoder.withIndent('  ');
      final jsonTeks = encoder.convert(kandungan);

      String duaDigit(int nombor) =>
          nombor.toString().padLeft(2, '0');

      final namaFail = 'SebutPro_Backup_'
          '${sekarang.year}'
          '${duaDigit(sekarang.month)}'
          '${duaDigit(sekarang.day)}_'
          '${duaDigit(sekarang.hour)}'
          '${duaDigit(sekarang.minute)}'
          '${duaDigit(sekarang.second)}.json';

      await muatTurunJson(namaFail, jsonTeks);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fail backup telah dihantar kepada pelayar '
            '(${
              dataBackup.length
            } kunci). Semak Downloads.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup gagal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          sedangBackup = false;
        });
      }
    }
  }

Future<void> semakFailRestore() async {
  try {
    final teks = await pilihFailBackup();

    if (teks == null) return;

    final kandungan = jsonDecode(teks);

    if (kandungan is! Map<String, dynamic> ||
        kandungan['aplikasi'] != 'SebutPro MY' ||
        kandungan['versi_backup'] != 1 ||
        kandungan['data'] is! Map<String, dynamic>) {
      throw const FormatException(
        'Format backup SebutPro MY tidak sah.',
      );
    }

    final data = kandungan['data'] as Map<String, dynamic>;
 
for (final kunci in kunciUtama) {
  if (!data.containsKey(kunci)) {
    throw FormatException(
      'Data utama tidak lengkap: $kunci',
    );
  }
}

for (final entry in data.entries) {
  final rekod = entry.value;

  if (rekod is! Map<String, dynamic>) {
    throw FormatException(
      'Struktur tidak sah: ${entry.key}',
    );
  }

  final jenis = rekod['jenis'];
  final nilai = rekod['nilai'];

  final sah = switch (jenis) {
    'string' => nilai is String,
    'stringList' => nilai is List &&
        nilai.every((item) => item is String),
    'bool' => nilai is bool,
    'int' => nilai is int,
    'double' => nilai is num,
    _ => false,
  };

  if (!sah) {
    throw FormatException(
      'Jenis data tidak sah: ${entry.key}',
    );
  }
}


    if (!mounted) return;

    
await showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: const Text('Pengesahan Fail Backup'),
    content: Text(
      'Fail backup SebutPro MY berjaya disemak.\n\n'
      'Jumlah kunci data: ${data.length}\n\n'
      'PERHATIAN:\n'
      'Proses Restore sebenar akan menggantikan '
      'data aplikasi yang sedang tersimpan.\n\n'
      'Pastikan anda mempunyai salinan backup '
      'sebelum meneruskan.\n\n'
      'MOD UJIAN: Tiada data akan diubah '
      'pada peringkat ini.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: const Text('Tutup'),
      ),
      
ElevatedButton(
  onPressed: () async {
    Navigator.pop(dialogContext);

    if (!mounted) return;

    final disahkan = await showDialog<bool>(
      context: context,
      builder: (contextPengesahan) => AlertDialog(
        title: const Text('Pengesahan Restore'),
        content: const Text(
          'Restore akan menggantikan data '
          'SebutPro MY yang sedang tersimpan.\n\n'
          'Pastikan fail backup telah disimpan '
          'di tempat yang selamat.\n\n'
          'MOD UJIAN: Tiada data akan diubah.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(contextPengesahan, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(contextPengesahan, true),
            child: const Text('Sahkan (Ujian)'),
          ),
        ],
      ),
    );
    
if (!mounted || disahkan != true) return;

try {
  await BackupRestoreService.pulihkan(data);

  if (!mounted) return;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Restore Berjaya'),
      content: const Text(
        'Data backup berjaya disimpan semula.\n\n'
        'Sila tutup dan buka semula SebutPro MY '
        'untuk memuatkan rekod yang dipulihkan.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  if (!mounted) return;
  await semakData();
} catch (e) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Restore gagal: $e'),
      backgroundColor: Colors.red,
    ),
  );
}

  },
  
child: const Text('Teruskan'),
),

    ],
  ),
);
     
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal membaca backup: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.backup_outlined,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          const Text(
            'Sandaran Data SebutPro MY',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (sedangMuat)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (ralat != null)
            Text(
              ralat!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            )
          else
            Text(
              '$jumlahDikesan daripada '
              '${kunciUtama.length} kunci data utama '
              'dikesan pada peranti ini.',
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.download_outlined,
                color: Colors.blue,
              ),
              title: const Text('Backup Data'),
              subtitle: const Text(
                'Eksport semua data tersimpan '
                'ke dalam fail JSON.',
              ),
              trailing: sedangBackup
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: sedangMuat ||
                      ralat != null ||
                      sedangBackup
                  ? null
                  : buatBackup,
            ),
          ),
          
Card(
  child: ListTile(
    leading: const Icon(Icons.upload_file_outlined),
    title: const Text('Restore Data'),
    subtitle: const Text(
      'Pilih dan semak fail backup JSON.',
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: semakFailRestore,
  ),
),

          const SizedBox(height: 20),
          const Text(
            'Penting: Simpan fail backup di tempat '
            'yang selamat. Fail ini mungkin mengandungi '
            'maklumat pelanggan, kewangan dan syarikat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
