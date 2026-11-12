
import 'package:flutter/material.dart';
import 'bq_editor_page.dart';

class BqTerperinciPage extends StatefulWidget {
  const BqTerperinciPage({super.key});

  @override
  State<BqTerperinciPage> createState() =>
      _BqTerperinciPageState();
}

class _BqTerperinciPageState
    extends State<BqTerperinciPage> {
  String formatDipilih = 'komersial';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BQ Terperinci'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'PILIH FORMAT BQ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Pilih format senarai kuantiti kerja '
            'yang sesuai dengan projek anda.',
          ),

          const SizedBox(height: 20),

          Card(
            child: RadioListTile<String>(
              title: const Text('BQ Komersial'),
              subtitle: const Text(
                'Sesuai untuk kontraktor kecil, '
                'renovasi dan kerja penyelenggaraan.',
              ),
              value: 'komersial',
              groupValue: formatDipilih,
              onChanged: (nilai) {
                if (nilai != null) {
                  setState(() {
                    formatDipilih = nilai;
                  });
                }
              },
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: RadioListTile<String>(
              title: const Text('BQ Gaya JKR'),
              subtitle: const Text(
                'Senarai kerja terperinci mengikut '
                'seksyen, huraian, unit dan kuantiti.',
              ),
              value: 'jkr',
              groupValue: formatDipilih,
              onChanged: (nilai) {
                if (nilai != null) {
                  setState(() {
                    formatDipilih = nilai;
                  });
                }
              },
            ),
          ),

          const SizedBox(height: 24),

          Card(
            color: const Color(0xFFE8EDF7),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FORMAT DIPILIH',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    formatDipilih == 'komersial'
                        ? 'BQ Komersial'
                        : 'BQ Gaya JKR',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF17345C),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    formatDipilih == 'komersial'
                        ? 'Bil. | Butiran Kerja | Unit | '
                          'Kuantiti | Kadar | Jumlah'
                        : 'Seksyen | Bil. | Huraian Kerja | '
                          'Unit | Kuantiti | Kadar | Jumlah',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BqEditorPage(
          format: formatDipilih,
        ),
      ),
    );
  },
  icon: const Icon(Icons.edit_document),
  label: const Text('Mula Sediakan BQ'),
),

const SizedBox(height: 12),

const Text(
  'Pilih format dan tekan Mula Sediakan BQ '
  'untuk menambah bahagian kerja.',
  textAlign: TextAlign.center,
  style: TextStyle(color: Colors.grey),
),

        ],
      ),
    );
  }
}
