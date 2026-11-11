
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RekodBayaranPage extends StatefulWidget {
  final Map<String, dynamic> invois;

  const RekodBayaranPage({
    super.key,
    required this.invois,
  });

  @override
  State<RekodBayaranPage> createState() =>
      _RekodBayaranPageState();
}

class _RekodBayaranPageState
    extends State<RekodBayaranPage> {
  final jumlahController = TextEditingController();
  final rujukanController = TextEditingController();
  final catatanController = TextEditingController();

  DateTime tarikhBayaran = DateTime.now();
  String kaedahBayaran = 'Transfer Bank';
  bool sedangSimpan = false;

  final kaedah = [
    'Transfer Bank',
    'Tunai',
    'Cek',
    'E-Wallet',
    'Lain-lain',
  ];

  double nombor(dynamic nilai) {
    if (nilai is num) return nilai.toDouble();

    return double.tryParse(
          nilai.toString().replaceAll(',', '').trim(),
        ) ??
        0;
  }

  int sen(dynamic nilai) =>
      (nombor(nilai) * 100).round();

  String wang(int nilaiSen) {
    final jumlah = nilaiSen / 100;
    final bahagian = jumlah.toStringAsFixed(2).split('.');

    final depan = bahagian[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return 'RM $depan.${bahagian[1]}';
  }

  String formatTarikh(DateTime nilai) {
    final hari = nilai.day.toString().padLeft(2, '0');
    final bulan = nilai.month.toString().padLeft(2, '0');

    return '$hari/$bulan/${nilai.year}';
  }

  int jumlahDibayar(Map<String, dynamic> invois) {
    final rekod = invois['rekod_bayaran'];
    if (rekod is! List) return 0;

    int jumlah = 0;

    for (final item in rekod) {
      if (item is Map) {
        jumlah += sen(item['jumlah']);
      }
    }

    return jumlah;
  }

  int bakiInvois(Map<String, dynamic> invois) {
    final baki =
        sen(invois['jumlah']) - jumlahDibayar(invois);

    return baki > 0 ? baki : 0;
  }

  Future<void> pilihTarikh() async {
    final pilihan = await showDatePicker(
      context: context,
      initialDate: tarikhBayaran,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pilihan != null && mounted) {
      setState(() {
        tarikhBayaran = pilihan;
      });
    }
  }

  Future<void> simpanBayaran() async {
    if (sedangSimpan) return;

    final teksJumlah = jumlahController.text.trim();
    final nilai = double.tryParse(
      teksJumlah.replaceAll(',', ''),
    );

    if (nilai == null ||
        !nilai.isFinite ||
        nilai <= 0 ||
        nilai > 999999999999 ||
        (nilai * 100 - (nilai * 100).round()).abs() >
            0.00001) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Masukkan jumlah bayaran sah, maksimum 2 perpuluhan.',
          ),
        ),
      );
      return;
    }

    if (kaedahBayaran != 'Tunai' &&
        rujukanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sila masukkan nombor rujukan transaksi.',
          ),
        ),
      );
      return;
    }

    final idInvois = widget.invois['id']?.toString();

    if (idInvois == null || idInvois.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID invois tidak sah.'),
        ),
      );
      return;
    }

    setState(() => sedangSimpan = true);

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final senarai =
          prefs.getStringList('senarai_invois') ?? [];

      final index = senarai.indexWhere((teks) {
        try {
          final data = jsonDecode(teks);
          return data is Map &&
              data['id']?.toString() == idInvois;
        } catch (_) {
          return false;
        }
      });

      if (index == -1) {
        throw StateError(
          'Invois asal tidak dijumpai.',
        );
      }

      final invois = Map<String, dynamic>.from(
        jsonDecode(senarai[index]) as Map,
      );

      final baki = bakiInvois(invois);
      final nilaiSen = (nilai * 100).round();

      if (baki <= 0) {
        throw StateError(
          'Invois ini telah dibayar sepenuhnya.',
        );
      }

      if (nilaiSen > baki) {
        throw StateError(
          'Bayaran melebihi baki ${wang(baki)}.',
        );
      }

      final rekodAsal = invois['rekod_bayaran'];

      final rekod = rekodAsal is List
          ? List<dynamic>.from(rekodAsal)
          : <dynamic>[];

      final tarikh =
          '${tarikhBayaran.year}-'
          '${tarikhBayaran.month.toString().padLeft(2, '0')}-'
          '${tarikhBayaran.day.toString().padLeft(2, '0')}';

      rekod.add({
        'id': DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        'tarikh': tarikh,
        'jumlah': nilaiSen / 100,
        'kaedah': kaedahBayaran,
        'rujukan': rujukanController.text.trim(),
        'catatan': catatanController.text.trim(),
      });

      invois['rekod_bayaran'] = rekod;

      final bakiBaru = bakiInvois(invois);
      final dibayarBaru = jumlahDibayar(invois);

      invois['status'] = dibayarBaru <= 0
          ? 'Belum Bayar'
          : bakiBaru > 0
              ? 'Bayar Sebahagian'
              : 'Selesai Bayar';

      senarai[index] = jsonEncode(invois);

      final berjaya = await prefs.setStringList(
        'senarai_invois',
        senarai,
      );

      if (!berjaya) {
        throw StateError('Gagal menyimpan bayaran.');
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is StateError
                ? e.message.toString()
                : 'Gagal merekod bayaran.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => sedangSimpan = false);
      }
    }
  }

  @override
  void dispose() {
    jumlahController.dispose();
    rujukanController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baki = bakiInvois(widget.invois);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekod Bayaran'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RINGKASAN INVOIS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No. Invois: '
                    '${widget.invois['nombor_invois'] ?? '-'}',
                  ),
                  Text(
                    'Jumlah: '
                    '${wang(sen(widget.invois['jumlah']))}',
                  ),
                  Text(
                    'Telah Dibayar: '
                    '${wang(jumlahDibayar(widget.invois))}',
                  ),
                  Text(
                    'Baki: ${wang(baki)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'MAKLUMAT BAYARAN',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: pilihTarikh,
            icon: const Icon(Icons.calendar_today),
            label: Text(
              'Tarikh: ${formatTarikh(tarikhBayaran)}',
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: jumlahController,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Jumlah Bayaran (RM)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: kaedahBayaran,
            decoration: const InputDecoration(
              labelText: 'Kaedah Pembayaran',
              border: OutlineInputBorder(),
            ),
            items: kaedah.map((nilai) {
              return DropdownMenuItem(
                value: nilai,
                child: Text(nilai),
              );
            }).toList(),
            onChanged: (nilai) {
              if (nilai != null) {
                setState(() => kaedahBayaran = nilai);
              }
            },
          ),

          const SizedBox(height: 16),

          TextField(
            controller: rujukanController,
            decoration: InputDecoration(
              labelText: kaedahBayaran == 'Tunai'
                  ? 'No. Rujukan (pilihan)'
                  : 'No. Rujukan Transaksi',
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: catatanController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan (pilihan)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          Builder(
            builder: (context) {
              final nilai = double.tryParse(
                    jumlahController.text
                        .replaceAll(',', '')
                        .trim(),
                  ) ??
                  0;

              final bakiBaru =
                  baki - (nilai * 100).round();

              return Text(
                'Baki Selepas Bayaran: '
                '${wang(bakiBaru > 0 ? bakiBaru : 0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed:
                sedangSimpan ? null : simpanBayaran,
            icon: const Icon(Icons.save_outlined),
            label: Text(
              sedangSimpan
                  ? 'Sedang Menyimpan...'
                  : 'Simpan Bayaran',
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
