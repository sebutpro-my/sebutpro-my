
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pelanggan_page.dart';

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

Future<void> padamPelanggan(
  Map<String, dynamic> pelanggan,
) async {
  final id = pelanggan['id']?.toString() ?? '';
  final nama = pelanggan['nama']?.toString() ?? '';

  if (id.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ID pelanggan tidak sah.'),
      ),
    );
    return;
  }

  final sah = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Padam Pelanggan?'),
      content: Text(
        'Adakah anda pasti mahu memadam '
        'rekod $nama?\n\n'
        'Tindakan ini tidak boleh dibatalkan.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext, false);
          },
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext, true);
          },
          child: const Text(
            'Padam',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  if (sah != true || !mounted) return;

  try {
    final prefs =
        await SharedPreferences.getInstance();

    final rekod = List<String>.from(
      prefs.getStringList('senarai_pelanggan') ??
          [],
    );

    final indeks = rekod.indexWhere((teks) {
      try {
        final data = jsonDecode(teks);

        return data is Map &&
            data['id']?.toString() == id;
      } catch (_) {
        return false;
      }
    });

    if (indeks < 0) {
      throw StateError(
        'Rekod pelanggan tidak ditemui.',
      );
    }

    rekod.removeAt(indeks);

    final berjaya = await prefs.setStringList(
      'senarai_pelanggan',
      rekod,
    );

    if (!berjaya) {
      throw StateError('Gagal menyimpan perubahan.');
    }

    if (!mounted) return;

    await muatPelanggan();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pelanggan berjaya dipadam.',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Gagal memadam pelanggan. Sila cuba lagi.',
        ),
      ),
    );
  }
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
        : () async {
            final berjaya = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const PelangganPage(),
              ),
            );

            if (!mounted) return;

            if (berjaya == true) {
              await muatPelanggan();
            }
          },
    icon: const Icon(Icons.person_add_alt_1),
    tooltip: 'Daftar Pelanggan',
  ),
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
                            
const SizedBox(height: 12),

const Divider(),

Align(
  alignment: Alignment.centerRight,
  child: OutlinedButton.icon(
    onPressed: () async {
      final berjaya = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PelangganPage(
            pelangganAsal:
                Map<String, dynamic>.from(pelanggan),
          ),
        ),
      );

      if (!mounted) return;

      if (berjaya == true) {
        await muatPelanggan();
      }
    },
    icon: const Icon(Icons.edit_outlined),
    label: const Text('Edit Pelanggan'),
  ),
),

const SizedBox(height: 8),

Align(
  alignment: Alignment.centerRight,
  child: OutlinedButton.icon(
    onPressed: () => padamPelanggan(pelanggan),
    icon: const Icon(
      Icons.delete_outline,
      color: Colors.red,
    ),
    label: const Text(
      'Padam Pelanggan',
      style: TextStyle(color: Colors.red),
    ),
  ),
),
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
