
import 'package:flutter/material.dart';
import 'invois_page.dart';

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
          
],
      ),
    );
  }
}
