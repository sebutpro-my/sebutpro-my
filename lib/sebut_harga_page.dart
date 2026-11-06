
import 'package:flutter/material.dart';

class SebutHargaPage extends StatefulWidget {
  const SebutHargaPage({super.key});

  @override
  State<SebutHargaPage> createState() => _SebutHargaPageState();
}

class _SebutHargaPageState extends State<SebutHargaPage> {
  final pelanggan = TextEditingController();
  final tajuk = TextEditingController();
  final kerja = TextEditingController();
  final kuantiti = TextEditingController();
  final kadar = TextEditingController();

  double get jumlah {
    final qty = double.tryParse(kuantiti.text) ?? 0;
    final rate = double.tryParse(kadar.text) ?? 0;
    return qty * rate;
  }

  @override
  void dispose() {
    pelanggan.dispose();
    tajuk.dispose();
    kerja.dispose();
    kuantiti.dispose();
    kadar.dispose();
    super.dispose();
  }

  Widget medan(
    String label,
    TextEditingController controller, {
    bool nombor = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: nombor
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sebut Harga Baharu'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          medan('Nama Pelanggan', pelanggan),
          medan('Tajuk Projek / Kerja', tajuk),
          medan('Butiran Kerja', kerja),
          medan('Kuantiti', kuantiti, nombor: true),
          medan('Kadar Harga (RM)', kadar, nombor: true),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Jumlah Keseluruhan'),
                  const SizedBox(height: 8),
                  Text(
                    'RM ${jumlah.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
