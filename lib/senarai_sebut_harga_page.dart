
import 'jana_pdf.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sebut_harga_page.dart';
class SenaraiSebutHargaPage extends StatefulWidget {
  const SenaraiSebutHargaPage({super.key});

  @override
  State<SenaraiSebutHargaPage> createState() =>
      _SenaraiSebutHargaPageState();
}

class _SenaraiSebutHargaPageState
    extends State<SenaraiSebutHargaPage> {
  List<Map<String, dynamic>> rekod = [];
  bool sedangMuat = true;

  @override
  void initState() {
    super.initState();
    muatRekod();
  }

  Future<void> muatRekod() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final senarai =
          prefs.getStringList('senarai_sebut_harga') ?? [];

      final data = senarai.map((teks) {
        return Map<String, dynamic>.from(
          jsonDecode(teks) as Map,
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        rekod = data.toList();
        sedangMuat = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        sedangMuat = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membaca rekod sebut harga'),
        ),
      );
    }
  }

  String formatWang(dynamic nilai) {
    final jumlah = (nilai is num)
        ? nilai.toDouble()
        : double.tryParse(nilai.toString()) ?? 0;

    final bahagian = jumlah.toStringAsFixed(2).split('.');
    final nombor = bahagian[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return 'RM $nombor.${bahagian[1]}';
  }

  String formatTarikh(dynamic nilai) {
    final tarikh = DateTime.tryParse(nilai?.toString() ?? '');

    if (tarikh == null) return '-';

    final hari = tarikh.day.toString().padLeft(2, '0');
    final bulan = tarikh.month.toString().padLeft(2, '0');

    return '$hari/$bulan/${tarikh.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Senarai Sebut Harga'),
      ),
      body: sedangMuat
          ? const Center(child: CircularProgressIndicator())
          : rekod.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Belum ada sebut harga disimpan.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: muatRekod,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rekod.length,
                    itemBuilder: (context, index) {
                      final data = rekod[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
  borderRadius: BorderRadius.circular(12),
  onTap: () {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['tajuk']?.toString() ?? 'Sebut Harga'),
        
content: SizedBox(
  width: double.maxFinite,
  child: SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pelanggan: ${data['pelanggan'] ?? '-'}'),
        Text('Tarikh: ${formatTarikh(data['tarikh'])}'),
        const SizedBox(height: 16),
        const Text(
          'Senarai Kerja',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Divider(),
        ...((data['items'] is List)
                ? (data['items'] as List)
                : <dynamic>[])
            .asMap()
            .entries
            .map((entry) {
          final item = entry.value;
          if (item is! Map) {
            return const SizedBox.shrink();
          }

          final butiran = item['butiran'] ?? '-';
          final unit = item['unit'] ?? '-';
          final kuantiti =
              double.tryParse('${item['kuantiti']}') ?? 0;
          final kadar =
              double.tryParse('${item['kadar']}') ?? 0;
          final jumlahItem = kuantiti * kadar;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key + 1}. $butiran',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$kuantiti $unit × ${formatWang(kadar)}',
                ),
                Text(
                  formatWang(jumlahItem),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
        const Divider(),
        Text(
          'Jumlah Keseluruhan: '
          '${formatWang(data['jumlah'])}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    ),
  ),
),

        
actions: [
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: const Text('Tutup'),
  ),
  ElevatedButton.icon(
    onPressed: () async {
      Navigator.pop(context);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SebutHargaPage(
            rekodEdit: Map<String, dynamic>.from(data),
            indeksEdit: index,
          ),
        ),
      );

      if (context.mounted) {
        await muatRekod();
      }
    },
    icon: const Icon(Icons.edit),
    label: const Text('Edit'),
  ),  
  TextButton.icon(
    onPressed: () async {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      final sahPadam = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Padam Sebut Harga?'),
          content: const Text(
            'Adakah anda pasti mahu memadam rekod ini? '
            'Tindakan ini tidak boleh dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text(
                'Padam',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (sahPadam != true || !mounted) return;

      try {
        final prefs = await SharedPreferences.getInstance();
        final senarai =
            prefs.getStringList('senarai_sebut_harga') ?? [];

        if (index < 0 || index >= senarai.length) {
          throw StateError('Rekod tidak ditemui');
        }

        senarai.removeAt(index);
        final berjaya = await prefs.setStringList(
          'senarai_sebut_harga',
          senarai,
        );

        if (!berjaya) {
          throw StateError('Gagal menyimpan perubahan');
        }

        if (!mounted) return;
        navigator.pop();
        await muatRekod();

        messenger.showSnackBar(
          const SnackBar(
            content: Text('Sebut harga berjaya dipadam'),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Gagal memadam sebut harga'),
          ),
        );
      }
    },
    icon: const Icon(
      Icons.delete_outline,
      color: Colors.red,
    ),
    label: const Text(
      'Padam',
      style: TextStyle(color: Colors.red),
    ),
  ),
  ElevatedButton.icon(
  onPressed: () async {
    try {
      await JanaPdf.jana(data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menjana PDF'),
        ),
      );
    }
  },
  icon: const Icon(Icons.picture_as_pdf_outlined),
  label: const Text('Jana PDF'),
),
],
      ),
    );
  },
  child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['tajuk']?.toString() ?? '-',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pelanggan: '
                                '${data['pelanggan'] ?? '-'}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tarikh: '
                                '${formatTarikh(data['tarikh'])}',
                              ),
                              const SizedBox(height: 12),
                              Text(
                                formatWang(data['jumlah']),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF17345C),
                                ),
                              ),
                            ],
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
