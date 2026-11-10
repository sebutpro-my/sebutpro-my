
import 'package:flutter/material.dart';

class InvoisPage extends StatefulWidget {
  const InvoisPage({super.key});

  @override
  State<InvoisPage> createState() => _InvoisPageState();
}

class _InvoisPageState extends State<InvoisPage> {
  final nomborInvois = TextEditingController();
  final pelanggan = TextEditingController();
  final tajuk = TextEditingController();

  @override
  void dispose() {
    nomborInvois.dispose();
    pelanggan.dispose();
    tajuk.dispose();
    super.dispose();
  }

  Widget medan(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
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
        title: const Text('Invois Baharu'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Maklumat Invois',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          medan('No. Invois', nomborInvois),
          medan('Nama Pelanggan', pelanggan),
          medan('Tajuk Projek / Kerja', tajuk),

          const SizedBox(height: 12),

          const Text(
            'Senarai Item Kerja',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Fungsi tambah item kerja akan '
            'dibina pada langkah seterusnya.',
          ),
        ],
      ),
    );
  }
}
