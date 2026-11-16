
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PilihPelangganPage extends StatefulWidget {
  const PilihPelangganPage({super.key});

  @override
  State<PilihPelangganPage> createState() =>
      _PilihPelangganPageState();
}

class _PilihPelangganPageState
    extends State<PilihPelangganPage> {
  final carian = TextEditingController();

  List<Map<String, dynamic>> senarai = [];
  bool sedangMuat = true;
  String? mesejRalat;

  @override
  void initState() {
    super.initState();
    muatPelanggan();
  }

  Future<void> muatPelanggan() async {
    setState(() {
      sedangMuat = true;
      mesejRalat = null;
    });

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final rekod = prefs.getStringList(
            'senarai_pelanggan',
          ) ??
          [];

      final hasil = <Map<String, dynamic>>[];

      for (final teks in rekod) {
        try {
          final data = jsonDecode(teks);

          if (data is Map) {
            hasil.add(
              Map<String, dynamic>.from(data),
            );
          }
        } catch (_) {
          // Abaikan rekod yang rosak.
        }
      }

      if (!mounted) return;

      setState(() {
        senarai = hasil.reversed.toList();
        sedangMuat = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        sedangMuat = false;
        mesejRalat =
            'Gagal memuatkan pelanggan.';
      });
    }
  }

  String baca(
    Map<String, dynamic> data,
    String kunci,
  ) {
    return data[kunci]?.toString().trim() ?? '';
  }

  @override
  void dispose() {
    carian.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kataCari =
        carian.text.trim().toLowerCase();

    final hasilCarian = senarai.where((data) {
      if (kataCari.isEmpty) return true;

      final teks = [
        baca(data, 'nama'),
        baca(data, 'syarikat'),
        baca(data, 'telefon'),
        baca(data, 'emel'),
      ].join(' ').toLowerCase();

      return teks.contains(kataCari);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Pelanggan'),
        actions: [
          IconButton(
            onPressed: sedangMuat
                ? null
                : muatPelanggan,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Semula',
          ),
        ],
      ),
      body: sedangMuat
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : mesejRalat != null
              ? Center(
                  child: Text(mesejRalat!),
                )
              : Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.all(16),
                      child: TextField(
                        controller: carian,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration:
                            const InputDecoration(
                          labelText: 'Cari Pelanggan',
                          hintText:
                              'Nama, syarikat atau telefon',
                          prefixIcon:
                              Icon(Icons.search),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: hasilCarian.isEmpty
                          ? const Center(
                              child: Text(
                                'Tiada pelanggan ditemui.',
                              ),
                            )
                          : ListView.builder(
                              itemCount:
                                  hasilCarian.length,
                              itemBuilder:
                                  (context, index) {
                                final pelanggan =
                                    hasilCarian[index];

                                final nama = baca(
                                  pelanggan,
                                  'nama',
                                );

                                final syarikat = baca(
                                  pelanggan,
                                  'syarikat',
                                );

                                final telefon = baca(
                                  pelanggan,
                                  'telefon',
                                );

                                return Card(
                                  margin:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 16,
                                    vertical: 5,
                                  ),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.person_outline,
                                    ),
                                    title: Text(
                                      nama.isEmpty
                                          ? 'Tanpa Nama'
                                          : nama,
                                    ),
                                    subtitle: Text(
                                      [
                                        syarikat,
                                        telefon,
                                      ]
                                          .where(
                                            (teks) =>
                                                teks.isNotEmpty,
                                          )
                                          .join('\n'),
                                    ),
                                    isThreeLine:
                                        syarikat.isNotEmpty &&
                                            telefon.isNotEmpty,
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                    ),
                                    onTap: () {
                                      Navigator.pop(
                                        context,
                                        pelanggan,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
