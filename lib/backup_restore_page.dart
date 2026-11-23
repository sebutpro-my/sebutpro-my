
import 'dart:convert';
import 'dart:html' as html;

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

      final blob = html.Blob(
        [utf8.encode(jsonTeks)],
        'application/json;charset=utf-8',
      );

      final url = html.Url.createObjectUrlFromBlob(blob);

      final pautan = html.AnchorElement(href: url)
        ..download = namaFail;

      pautan.click();

      await Future<void>.delayed(
        const Duration(seconds: 2),
      );

      html.Url.revokeObjectUrl(url);

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
          const Card(
            child: ListTile(
              leading: Icon(Icons.upload_file_outlined),
              title: Text('Restore Data'),
              subtitle: Text(
                'Akan diaktifkan selepas '
                'fungsi backup diuji.',
              ),
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
