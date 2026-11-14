
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bq_editor_page.dart';

class SenaraiBqPage extends StatefulWidget {
  const SenaraiBqPage({super.key});

  @override
  State<SenaraiBqPage> createState() =>
      _SenaraiBqPageState();
}

class _SenaraiBqPageState extends State<SenaraiBqPage> {
  List<Map<String, dynamic>> senarai = [];
  bool sedangMuat = true;

  @override
  void initState() {
    super.initState();
    muatBQ();
  }

  double nombor(dynamic nilai) {
    if (nilai is num) return nilai.toDouble();

    return double.tryParse(
          nilai.toString().replaceAll(',', ''),
        ) ??
        0;
  }

  String wang(dynamic nilai) {
    final bahagian = nombor(nilai)
        .toStringAsFixed(2)
        .split('.');

    final depan = bahagian[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (padanan) => ',',
    );

    return 'RM $depan.${bahagian[1]}';
  }

  String tarikh(dynamic nilai) {
    final data = DateTime.tryParse(
      nilai?.toString() ?? '',
    );

    if (data == null) return '-';

    final hari = data.day.toString().padLeft(2, '0');
    final bulan = data.month.toString().padLeft(2, '0');

    return '$hari/$bulan/${data.year}';
  }

  String namaFormat(dynamic nilai) {
    final format = nilai?.toString() ?? '';

    if (format.toLowerCase().contains('jkr')) {
      return 'BQ Gaya JKR';
    }

    return 'BQ Komersial';
  }

  Future<void> muatBQ() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final data = prefs.getStringList('senarai_bq') ?? [];

      final hasil = <Map<String, dynamic>>[];

      for (final teks in data) {
        try {
          final rekod = jsonDecode(teks);

          if (rekod is Map) {
            hasil.add(
              Map<String, dynamic>.from(rekod),
            );
          }
        } catch (_) {
          continue;
        }
      }

      hasil.sort((a, b) {
        final tarikhA =
            a['dikemaskini']?.toString() ?? '';
        final tarikhB =
            b['dikemaskini']?.toString() ?? '';

        return tarikhB.compareTo(tarikhA);
      });

      if (!mounted) return;

      setState(() {
        senarai = hasil;
        sedangMuat = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        sedangMuat = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuatkan senarai BQ.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Senarai BQ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Semula',
            onPressed: muatBQ,
          ),
        ],
      ),
      body: sedangMuat
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: muatBQ,
              child: senarai.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'Belum ada BQ disimpan.',
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: senarai.length,
                      itemBuilder: (context, index) {
                        final rekod = senarai[index];

                        final bahagian = rekod['bahagian'];
                        final bilangan = bahagian is List
                            ? bahagian.length
                            : 0;

                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rekod['tajuk']?.toString() ??
                                      'Tanpa Tajuk',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  namaFormat(rekod['format']),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tarikh: ${tarikh(rekod['tarikh'])}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$bilangan bahagian kerja',
                                ),
                                const Divider(),
                                Text(
                                  wang(rekod['jumlah']),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF17345C),
                                  ),
                                ),
                              
const SizedBox(height: 12),

OutlinedButton.icon(
  onPressed: () async {
    final format = rekod['format']?.toString() ?? '';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BqEditorPage(
          format: format,
          bqAsal: Map<String, dynamic>.from(rekod),
        ),
      ),
    );

    if (!mounted) return;
    await muatBQ();
  },
  icon: const Icon(Icons.edit_outlined),
  label: const Text('Buka / Edit BQ'),
),
],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
