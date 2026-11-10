
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'butiran_invois_page.dart';

class SenaraiInvoisPage extends StatefulWidget {
  const SenaraiInvoisPage({super.key});

  @override
  State<SenaraiInvoisPage> createState() =>
      _SenaraiInvoisPageState();
}

class _SenaraiInvoisPageState
    extends State<SenaraiInvoisPage> {
  List<Map<String, dynamic>> senarai = [];
  bool sedangMuat = true;

  @override
  void initState() {
    super.initState();
    muatInvois();
  }

  Future<void> muatInvois() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rekod =
          prefs.getStringList('senarai_invois') ?? [];

      final hasil = <Map<String, dynamic>>[];

      for (final teks in rekod) {
        final data = jsonDecode(teks);

        if (data is Map) {
          hasil.add(Map<String, dynamic>.from(data));
        }
      }

      if (!mounted) return;

      setState(() {
        senarai = hasil.reversed.toList();
        sedangMuat = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => sedangMuat = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuatkan senarai invois.'),
        ),
      );
    }
  }

  String wang(dynamic nilai) {
    final nombor =
        double.tryParse(nilai.toString()) ?? 0;

    final bahagian =
        nombor.toStringAsFixed(2).split('.');

    final depan = bahagian[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return 'RM $depan.${bahagian[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Senarai Invois'),
      ),
      body: sedangMuat
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : senarai.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada invois disimpan.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: muatInvois,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: senarai.length,
                    itemBuilder: (context, index) {
                      final data = senarai[index];

                      final nombor =
                          data['nombor_invois']
                                  ?.toString() ??
                              '-';

                      final pelanggan =
                          data['pelanggan']
                                  ?.toString() ??
                              '-';

                      final tajuk =
                          data['tajuk']?.toString() ?? '-';

                      final status =
                          data['status']?.toString() ??
                              'Belum Bayar';

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ButiranInvoisPage(
                                  data: data,
                                ),
                              ),
                            );
                          },
                          title: Text(
                            nombor,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '$pelanggan\n'
                            '$tajuk\n'
                            'Status: $status',
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            wang(data['jumlah']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF17345C),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
