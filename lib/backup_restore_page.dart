
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const Center(child: CircularProgressIndicator())
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
            const Card(
              child: ListTile(
                leading: Icon(Icons.download_outlined),
                title: Text('Backup Data'),
                subtitle: Text(
                  'Fungsi eksport akan ditambah '
                  'dalam peringkat seterusnya.',
                ),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.upload_file_outlined),
                title: Text('Restore Data'),
                subtitle: Text(
                  'Fungsi import akan ditambah '
                  'selepas eksport diuji.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
