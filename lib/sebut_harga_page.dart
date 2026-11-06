
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SebutHargaPage extends StatefulWidget {
  const SebutHargaPage({super.key});

  @override
  State<SebutHargaPage> createState() => _SebutHargaPageState();
}

class _ItemKerja {
  final butiran = TextEditingController();
  final kuantiti = TextEditingController();
  final kadar = TextEditingController();
  String unit = 'm²';

  double get jumlah {
    final qty = double.tryParse(
          kuantiti.text.replaceAll(',', ''),
        ) ??
        0;
    final rate = double.tryParse(
          kadar.text.replaceAll(',', ''),
        ) ??
        0;
    return qty * rate;
  }

  void dispose() {
    butiran.dispose();
    kuantiti.dispose();
    kadar.dispose();
  }
}

class _SebutHargaPageState extends State<SebutHargaPage> {
  final pelanggan = TextEditingController();
  final tajuk = TextEditingController();
  Future<void> simpanSebutHarga() async {
  final data = {
    'pelanggan': pelanggan.text,
    'tajuk': tajuk.text,
    'tarikh': DateTime.now().toIso8601String(),
    'items': items.map((item) => {
      'butiran': item.butiran.text,
      'unit': item.unit,
      'kuantiti': item.kuantiti.text,
      'kadar': item.kadar.text,
    }).toList(),
    'jumlah': jumlahKeseluruhan,
  };

  final prefs = await SharedPreferences.getInstance();
  final senarai = prefs.getStringList('senarai_sebut_harga') ?? [];
  senarai.add(jsonEncode(data));

  await prefs.setStringList('senarai_sebut_harga', senarai);
}
  final List<_ItemKerja> items = [_ItemKerja()];

  static const List<String> units = [
    'm²',
    'm³',
    'm',
    'kaki²',
    'kaki',
    'unit',
    'nos',
    'LS',
    'set',
    'kg',
  ];

  double get jumlahKeseluruhan {
    return items.fold(
      0.0,
      (total, item) => total + item.jumlah,
    );
  }

  String wang(double nilai) {
    final bahagian = nilai.toStringAsFixed(2).split('.');
    final nombor = bahagian[0];
    final formatted = nombor.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'RM $formatted.${bahagian[1]}';
  }

  void tambahItem() {
    setState(() {
      items.add(_ItemKerja());
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
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: nombor
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget kadItem(int index) {
    final item = items[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Item Kerja ${index + 1}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (items.length > 1)
                  IconButton(
                    tooltip: 'Padam item',
                    onPressed: () => padamItem(index),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            medan(
              'Butiran Kerja',
              item.butiran,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: item.unit,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Unit Ukuran',
                border: OutlineInputBorder(),
              ),
              items: units.map((unit) {
                return DropdownMenuItem(
                  value: unit,
                  child: Text(unit),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => item.unit = value);
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: medan(
                    'Kuantiti',
                    item.kuantiti,
                    nombor: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: medan(
                    'Kadar (RM)',
                    item.kadar,
                    nombor: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Jumlah: ${wang(item.jumlah)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
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
        title: const Text('Sebut Harga Baharu'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Maklumat Pelanggan & Projek',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          medan('Nama Pelanggan', pelanggan),
          const SizedBox(height: 12),
          medan('Tajuk Projek / Kerja', tajuk),
          const SizedBox(height: 24),
          const Text(
            'Senarai Item Kerja',
            style: TextStyle(
              fontSize: 19,
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Jumlah Keseluruhan'),
                  const SizedBox(height: 8),
                  Text(
                    wang(jumlahKeseluruhan),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF17345C),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ElevatedButton.icon(
  onPressed: () async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await simpanSebutHarga();

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Sebut harga berjaya disimpan'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan sebut harga'),
        ),
      );
    }
  },
  icon: const Icon(Icons.save_outlined),
  label: const Text('Simpan Sebut Harga'),
),
],
      ),
    );
  }
}
