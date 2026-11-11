
import 'package:flutter/material.dart';
import 'invois_page.dart';
import 'jana_pdf_invois.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ButiranInvoisPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const ButiranInvoisPage({
    super.key,
    required this.data,
  });

  double nombor(dynamic nilai) {
    if (nilai is num) return nilai.toDouble();

    return double.tryParse(
          nilai.toString().replaceAll(',', '').trim(),
        ) ??
        0;
  }

  String wang(dynamic nilai) {
    final jumlah = nombor(nilai);
    final bahagian = jumlah.toStringAsFixed(2).split('.');

    final depan = bahagian[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return 'RM $depan.${bahagian[1]}';
  }

Future<void> padamInvois(BuildContext context) async {
  final idAsal = data['id']?.toString();

  if (idAsal == null || idAsal.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ID invois tidak sah.'),
      ),
    );
    return;
  }

  final sahkan = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Padam Invois?'),
      content: const Text(
        'Adakah anda pasti mahu memadam invois ini? '
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

  if (sahkan != true || !context.mounted) return;

  try {
    final prefs = await SharedPreferences.getInstance();

    final senarai =
        prefs.getStringList('senarai_invois') ?? [];

    final indexAsal = senarai.indexWhere((teks) {
      try {
        final rekod = jsonDecode(teks);
        return rekod is Map &&
            rekod['id']?.toString() == idAsal;
      } catch (_) {
        return false;
      }
    });

    if (indexAsal == -1) {
      throw StateError('Rekod invois tidak dijumpai.');
    }

    senarai.removeAt(indexAsal);

    final berjaya = await prefs.setStringList(
      'senarai_invois',
      senarai,
    );

    if (!berjaya) {
      throw StateError('Gagal memadam invois.');
    }

    if (!context.mounted) return;

    Navigator.pop(context, true);
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e is StateError
              ? e.message.toString()
              : 'Gagal memadam invois.',
        ),
      ),
    );
  }
}
  
@override
  Widget build(BuildContext context) {
    final noInvois =
        data['nombor_invois']?.toString() ?? '-';

    final pelanggan =
        data['pelanggan']?.toString() ?? '-';

    final tajuk =
        data['tajuk']?.toString() ?? '-';

    final status =
        data['status']?.toString() ?? 'Belum Bayar';

    final itemAsal = data['items'];
    final items = itemAsal is List ? itemAsal : [];
    
final jumlahInvois = nombor(data['jumlah']);

final rekodAsal = data['rekod_bayaran'];
final rekodBayaran =
    rekodAsal is List ? rekodAsal : [];

double jumlahDibayar = 0;

for (final rekod in rekodBayaran) {
  if (rekod is Map) {
    jumlahDibayar += nombor(rekod['jumlah']);
  }
}

final bakiBayaran =
    (jumlahInvois - jumlahDibayar).clamp(
  0.0,
  double.infinity,
);

final statusBayaran = jumlahDibayar <= 0
    ? 'Belum Bayar'
    : bakiBayaran > 0
        ? 'Bayar Sebahagian'
        : 'Selesai Bayar';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Butiran Invois'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'MAKLUMAT INVOIS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Text('No. Invois: $noInvois'),
          const SizedBox(height: 8),

          Text('Pelanggan: $pelanggan'),
          const SizedBox(height: 8),

          Text('Tajuk Kerja: $tajuk'),
          const SizedBox(height: 8),

          Text('Status: $status'),

          const SizedBox(height: 24),

          const Text(
            'SENARAI ITEM KERJA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          for (int i = 0; i < items.length; i++)
            if (items[i] is Map)
              Builder(
                builder: (context) {
                  final item = items[i] as Map;

                  final butiran =
                      item['butiran']?.toString() ?? '-';

                  final unit =
                      item['unit']?.toString() ?? 'unit';

                  final qty = nombor(item['kuantiti']);
                  final kadar = nombor(item['kadar']);
                  final jumlah = qty * kadar;

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Item ${i + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(butiran),
                          const SizedBox(height: 8),

                          Text(
                            'Kuantiti: $qty $unit',
                          ),

                          Text(
                            'Kadar: ${wang(kadar)}',
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Jumlah: ${wang(jumlah)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

          const SizedBox(height: 16),

          Card(
            color: const Color(0xFFE8EDF7),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'JUMLAH KESELURUHAN\n'
                '${wang(data['jumlah'])}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF17345C),
                ),
              ),
            ),
          ),

const SizedBox(height: 16),

Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RINGKASAN PEMBAYARAN',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Jumlah Invois: ${wang(jumlahInvois)}',
        ),

        const SizedBox(height: 8),

        Text(
          'Jumlah Dibayar: ${wang(jumlahDibayar)}',
        ),

        const SizedBox(height: 8),

        Text(
          'Baki Tertunggak: ${wang(bakiBayaran)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Status: $statusBayaran',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF17345C),
          ),
        ),
      ],
    ),
  ),
),

          const SizedBox(height: 24),
        
ElevatedButton.icon(
  onPressed: () async {
    final berjaya = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => InvoisPage(
          invoisAsal: data,
        ),
      ),
    );

    if (!context.mounted) return;

    if (berjaya == true) {
      Navigator.pop(context, true);
    }
  },
  icon: const Icon(Icons.edit_outlined),
  label: const Text('Edit Invois'),
),
          
const SizedBox(height: 12),

OutlinedButton.icon(
  onPressed: () => padamInvois(context),
  icon: const Icon(Icons.delete_outline),
  label: const Text('Padam Invois'),
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.red,
    side: const BorderSide(color: Colors.red),
  ),
),

const SizedBox(height: 12),

ElevatedButton.icon(
  onPressed: () async {
    try {
      await JanaPdfInvois.jana(data);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal menjana PDF Invois.',
          ),
        ),
      );
    }
  },
  icon: const Icon(Icons.picture_as_pdf_outlined),
  label: const Text('Jana PDF Invois'),
),

],
      ),
    );
  }
}
