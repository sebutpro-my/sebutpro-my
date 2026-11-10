
import 'package:flutter/material.dart';

class InvoisPage extends StatefulWidget {
  const InvoisPage({super.key});

  @override
  State<InvoisPage> createState() => _InvoisPageState();
}

class _ItemInvois {
  final butiran = TextEditingController();
  final kuantiti = TextEditingController(text: '1');
  final kadar = TextEditingController(text: '0');
  String unit = 'unit';

  double get jumlah {
    final qty = double.tryParse(
          kuantiti.text.replaceAll(',', '').trim(),
        ) ??
        0;
    final rate = double.tryParse(
          kadar.text.replaceAll(',', '').trim(),
        ) ??
        0;

    if (!qty.isFinite || !rate.isFinite) return 0;
    if (qty < 0 || rate < 0) return 0;

    return qty * rate;
  }

  void dispose() {
    butiran.dispose();
    kuantiti.dispose();
    kadar.dispose();
  }
}

class _InvoisPageState extends State<InvoisPage> {
  final nomborInvois = TextEditingController();
  final pelanggan = TextEditingController();
  final tajuk = TextEditingController();

  final List<_ItemInvois> items = [_ItemInvois()];

  static const units = [
    'unit',
    'nos',
    'm²',
    'm³',
    'm',
    'kaki²',
    'kaki',
    'LS',
    'set',
    'kg',
  ];

  double get jumlahKeseluruhan {
    return items.fold<double>(
      0,
      (jumlah, item) => jumlah + item.jumlah,
    );
  }

  String wang(double nilai) {
    final bahagian = nilai.toStringAsFixed(2).split('.');
    final depan = bahagian[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'RM $depan.${bahagian[1]}';
  }

  void tambahItem() {
    setState(() {
      items.add(_ItemInvois());
    });
  }

  void padamItem(int index) {
    if (items.length <= 1) return;

    final item = items.removeAt(index);
    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      item.dispose();
    });
  }

  @override
  void dispose() {
    nomborInvois.dispose();
    pelanggan.dispose();
    tajuk.dispose();

    for (final item in items) {
      item.dispose();
    }

    super.dispose();
  }

  Widget medan(
    String label,
    TextEditingController controller, {
    bool nombor = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: nombor
            ? const TextInputType.numberWithOptions(
                decimal: true,
              )
            : TextInputType.text,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget kadItem(int index) {
    final item = items[index];

    return Card(
      key: ObjectKey(item),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Item ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: items.length > 1
                      ? () => padamItem(index)
                      : null,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),

            medan('Butiran Kerja', item.butiran),

            DropdownButtonFormField<String>(
              initialValue: item.unit,
              decoration: const InputDecoration(
                labelText: 'Unit',
                border: OutlineInputBorder(),
              ),
              items: units.map((unit) {
                return DropdownMenuItem(
                  value: unit,
                  child: Text(unit),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  item.unit = value;
                });
              },
            ),

            const SizedBox(height: 12),

            medan(
              'Kuantiti',
              item.kuantiti,
              nombor: true,
            ),

            medan(
              'Kadar (RM)',
              item.kadar,
              nombor: true,
            ),

            Text(
              'Jumlah Item: ${wang(item.jumlah)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF17345C),
              ),
            ),
          ],
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

          const SizedBox(height: 20),

          const Text(
            'Senarai Item Kerja',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          for (int i = 0; i < items.length; i++)
            kadItem(i),

          OutlinedButton.icon(
            onPressed: tambahItem,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Tambah Item Kerja'),
          ),

          const SizedBox(height: 24),

          Card(
            color: const Color(0xFFE8EDF7),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'JUMLAH KESELURUHAN\n'
                '${wang(jumlahKeseluruhan)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF17345C),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
