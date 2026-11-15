
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SenaraiPelangganPage extends StatefulWidget {
  const SenaraiPelangganPage({super.key});

  @override
  State<SenaraiPelangganPage> createState() =>
      _SenaraiPelangganPageState();
}

class _SenaraiPelangganPageState
    extends State<SenaraiPelangganPage> {
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
    if (!mounted) return;

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
          // Rekod rosak tidak dipaparkan.
          // Data asal tidak dipadam.
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
            'Gagal memuatkan senarai pelanggan.';
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
    final kataCari = carian.text.trim().toLowerCase();

    final hasilCarian = senarai.where((pelanggan) {
      if (kataCari.isEmpty) return true;

      final maklumat = [
        baca(pelanggan, 'nama'),
        baca(pelanggan, 'syarikat'),
        baca(pelanggan, 'telefon'),
        baca(pelanggan, 'emel'),
      ].join(' ').toLowerCase();

      return maklumat.contains(kataCari);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Senarai Pelanggan'),
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
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(mesejRalat!),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: muatPelanggan,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextField(
                        controller: carian,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration: const InputDecoration(
                          labelText: 'Cari Pelanggan',
                          hintText:
                              'Nama, syarikat, telefon atau e-mel',
                          prefixIcon:
                              Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        '${hasilCarian.length} pelanggan',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF17345C),
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (hasilCarian.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'Tiada pelanggan ditemui.',
                              ),
                            ),
                          ),
                        ),

                      for (final pelanggan in hasilCarian)
                        Card(
                          margin: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      color:
                                          Color(0xFF17345C),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Expanded(
                                      child: Text(
                                        baca(
                                          pelanggan,
                                          'nama',
                                        ),
                                        style:
                                            const TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                if (baca(
                                  pelanggan,
                                  'syarikat',
                                ).isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    baca(
                                      pelanggan,
                                      'syarikat',
                                    ),
                                  ),
                                ],

                                if (baca(
                                  pelanggan,
                                  'telefon',
                                ).isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Telefon: ${baca(pelanggan, 'telefon')}',
                                  ),
                                ],

                                if (baca(
                                  pelanggan,
                                  'emel',
                                ).isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'E-mel: ${baca(pelanggan, 'emel')}',
                                  ),
                                ],

                                if (baca(
                                  pelanggan,
                                  'alamat',
                                ).isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Alamat: ${baca(pelanggan, 'alamat')}',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }
}
