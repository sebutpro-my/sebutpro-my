
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sebut_harga_page.dart';

class PilihBqSebutHargaPage extends StatefulWidget {
  const PilihBqSebutHargaPage({super.key});

  @override
  State<PilihBqSebutHargaPage> createState() =>
      _PilihBqSebutHargaPageState();
}

class _PilihBqSebutHargaPageState
    extends State<PilihBqSebutHargaPage> {
  List<Map<String, dynamic>> senaraiBq = [];
  bool sedangMuat = true;

  @override
  void initState() {
    super.initState();
    muatBq();
  }

  Future<void> muatBq() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final senarai =
          prefs.getStringList('senarai_bq') ?? [];

      final hasil = <Map<String, dynamic>>[];

      for (final teks in senarai) {
        try {
          final data = jsonDecode(teks);

          if (data is Map) {
            hasil.add(
              Map<String, dynamic>.from(data),
            );
          }
        } catch (_) {
          // Abaikan rekod yang tidak sah.
        }
      }

      if (!mounted) return;

      setState(() {
        senaraiBq = hasil.reversed.toList();
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

  String formatWang(dynamic nilai) {
    final jumlah = nilai is num
        ? nilai.toDouble()
        : double.tryParse(nilai?.toString() ?? '') ?? 0;

    return 'RM ${jumlah.toStringAsFixed(2)}';
  }

  Future<void> pilihBq(Map<String, dynamic> bq) async {
    final bahagian = bq['bahagian'];

    if (bahagian is! List || bahagian.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'BQ ini belum mempunyai bahagian kerja.',
          ),
        ),
      );
      return;
    }

    bool adaItem = false;

    for (final seksyen in bahagian) {
      if (seksyen is! Map) continue;

      final items = seksyen['items'];
      if (items is! List) continue;

      for (final item in items) {
        if (item is Map &&
            (item['butiran']
                    ?.toString()
                    .trim()
                    .isNotEmpty ??
                false)) {
          adaItem = true;
          break;
        }
      }

      if (adaItem) break;
    }

    if (!adaItem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'BQ ini belum mempunyai item kerja.',
          ),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SebutHargaPage(
          bqAsal: Map<String, dynamic>.from(bq),
        ),
      ),
    );

    if (!mounted) return;
    await muatBq();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih BQ Tersimpan'),
      ),
      body: sedangMuat
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : senaraiBq.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Belum ada BQ tersimpan.\n'
                      'Sila sediakan BQ terlebih dahulu.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: muatBq,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: senaraiBq.length,
                    itemBuilder: (context, index) {
                      final bq = senaraiBq[index];

                      final tajuk =
                          bq['tajuk']?.toString() ??
                              'Tanpa Tajuk';

                      final format =
                          bq['format']?.toString() ==
                                  'jkr'
                              ? 'BQ Gaya JKR'
                              : 'BQ Komersial';

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.description_outlined,
                          ),
                          title: Text(tajuk),
                          subtitle: Text(
                            '$format\n'
                            '${formatWang(bq['jumlah'])}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => pilihBq(bq),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
