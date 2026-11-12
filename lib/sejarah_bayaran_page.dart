
import 'package:flutter/material.dart';
import 'jana_pdf_resit.dart';

class SejarahBayaranPage extends StatelessWidget {
  final Map<String, dynamic> invois;

  const SejarahBayaranPage({
    super.key,
    required this.invois,
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

  String formatTarikh(dynamic nilai) {
    final tarikh = DateTime.tryParse(
      nilai?.toString() ?? '',
    );

    if (tarikh == null) return '-';

    final hari = tarikh.day.toString().padLeft(2, '0');
    final bulan = tarikh.month.toString().padLeft(2, '0');

    return '$hari/$bulan/${tarikh.year}';
  }

  @override
  Widget build(BuildContext context) {
    final asal = invois['rekod_bayaran'];

    final rekod = asal is List
        ? asal.whereType<Map>().toList()
        : <Map>[];

    final jumlahInvois = nombor(invois['jumlah']);

    double jumlahDibayar = 0;

    for (final bayaran in rekod) {
      jumlahDibayar += nombor(bayaran['jumlah']);
    }

    final baki = (jumlahInvois - jumlahDibayar)
        .clamp(0.0, double.infinity);

    final status = jumlahDibayar <= 0
        ? 'Belum Bayar'
        : baki > 0
            ? 'Bayar Sebahagian'
            : 'Selesai Bayar';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sejarah Pembayaran'),
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
                    'RINGKASAN PEMBAYARAN',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'No. Invois: '
                    '${invois['nombor_invois'] ?? '-'}',
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Jumlah Invois: ${wang(jumlahInvois)}',
                  ),
                  Text(
                    'Jumlah Dibayar: ${wang(jumlahDibayar)}',
                  ),
                  Text(
                    'Baki Tertunggak: ${wang(baki)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Status: $status',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF17345C),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'SENARAI TRANSAKSI',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (rekod.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Belum ada rekod pembayaran.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          for (int i = 0; i < rekod.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Bayaran ${i + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          wang(rekod[i]['jumlah']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF17345C),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Tarikh: '
                      '${formatTarikh(rekod[i]['tarikh'])}',
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Kaedah: '
                      '${rekod[i]['kaedah'] ?? '-'}',
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'No. Rujukan: '
                      '${(rekod[i]['rujukan']?.toString().trim().isNotEmpty ?? false) ? rekod[i]['rujukan'] : '-'}',
                    ),

                    if ((rekod[i]['catatan']
                                ?.toString()
                                .trim()
                                .isNotEmpty ??
                            false)) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Catatan: ${rekod[i]['catatan']}',
                      ),
                    ],
                  
const SizedBox(height: 16),

OutlinedButton.icon(
  onPressed: () async {
    try {
      await JanaPdfResit.jana(
        invois,
        Map<String, dynamic>.from(rekod[i]),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal menjana PDF Resit.',
          ),
        ),
      );
    }
  },
  icon: const Icon(Icons.receipt_long_outlined),
  label: const Text('Jana Resit PDF'),
),
],
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
