
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SebutHargaPage extends StatefulWidget {
  final Map<String, dynamic>? rekodEdit;
  final int? indeksEdit;

  const SebutHargaPage({
    super.key,
    this.rekodEdit,
    this.indeksEdit,
  });

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
  final rujukan = TextEditingController();
  String modRujukan = 'manual';
  int turutanRujukan = 1;
  
final deposit = TextEditingController(text: '30');

final tempohSah = TextEditingController(text: '30');

final termaPembayaran = TextEditingController(
  text: 'Bayaran deposit diperlukan sebelum kerja '
      'dimulakan. Baki bayaran dijelaskan selepas '
      'kerja siap.',
);

  @override
  void initState() {
    super.initState();
    muatTetapanRujukan();
    
    final data = widget.rekodEdit;
    if (data == null) return;

    pelanggan.text = data['pelanggan']?.toString() ?? '';
    tajuk.text = data['tajuk']?.toString() ?? '';
    rujukan.text = data['rujukan']?.toString() ?? '';
    
deposit.text =
    data['deposit']?.toString() ?? '30';

tempohSah.text =
    data['tempoh_sah']?.toString() ?? '30';

termaPembayaran.text =
    data['terma_pembayaran']?.toString() ??
    'Bayaran deposit diperlukan sebelum kerja '
    'dimulakan. Baki bayaran dijelaskan selepas '
    'kerja siap.';

    final itemLama = data['items'];

    if (itemLama is List) {
      for (final item in items) {
        item.dispose();
      }
      items.clear();

      for (final rekod in itemLama) {
        if (rekod is! Map) continue;

        final item = _ItemKerja();
        item.butiran.text = rekod['butiran']?.toString() ?? '';
        item.unit = rekod['unit']?.toString() ?? 'm²';
        item.kuantiti.text = rekod['kuantiti']?.toString() ?? '';
        item.kadar.text = rekod['kadar']?.toString() ?? '';

        items.add(item);
      }

      if (items.isEmpty) {
        items.add(_ItemKerja());
      }
    }
  }
  
Future<void> muatTetapanRujukan() async {
  final prefs = await SharedPreferences.getInstance();

  final mod = prefs.getString('rujukan_mod') ?? 'manual';
  final awalan = prefs.getString('rujukan_awalan') ?? 'SH/2026/';
  final turutan = prefs.getInt('rujukan_turutan') ?? 1;

  if (!mounted) return;

  setState(() {
    modRujukan = mod;
    turutanRujukan = turutan;

    if (widget.rekodEdit == null && mod == 'auto') {
      rujukan.text = '$awalan${turutan.toString().padLeft(4, '0')}';
    }
  });
}

  Future<void> simpanSebutHarga() async {
  
final teksDeposit = deposit.text.trim();
final teksTempoh = tempohSah.text.trim();

final nilaiDeposit = teksDeposit.isEmpty
    ? null
    : double.tryParse(teksDeposit);

final nilaiTempoh = teksTempoh.isEmpty
    ? null
    : int.tryParse(teksTempoh);

if (teksDeposit.isNotEmpty &&
    (nilaiDeposit == null ||
        !nilaiDeposit.isFinite ||
        nilaiDeposit < 0 ||
        nilaiDeposit > 100)) {
  throw StateError(
    'Deposit mesti antara 0% hingga 100%',
  );
}

if (teksTempoh.isNotEmpty &&
    (nilaiTempoh == null ||
        nilaiTempoh < 1 ||
        nilaiTempoh > 365)) {
  throw StateError(
    'Tempoh sah mesti antara 1 hingga 365 hari',
  );
}
final data = {
    'pelanggan': pelanggan.text,
    'tajuk': tajuk.text,
    'rujukan': rujukan.text.trim(),
    'deposit': deposit.text.trim(),
    'tempoh_sah': tempohSah.text.trim(),
    'terma_pembayaran': termaPembayaran.text.trim(),
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
  
final nomborRujukan = rujukan.text.trim().toLowerCase();

if (nomborRujukan.isEmpty) {
  throw StateError('Sila isi nombor rujukan sebut harga');
}

for (var i = 0; i < senarai.length; i++) {
  if (widget.indeksEdit == i) continue;

  final rekod = jsonDecode(senarai[i]);

  if (rekod is! Map) continue;

  final rujukanLama =
      (rekod['rujukan'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

  if (rujukanLama == nomborRujukan) {
    throw StateError(
      'Nombor rujukan ini telah digunakan. '
      'Sila masukkan nombor lain.',
    );
  }
}
if (widget.indeksEdit != null &&
    widget.indeksEdit! >= 0 &&
    widget.indeksEdit! < senarai.length) {
  senarai[widget.indeksEdit!] = jsonEncode(data);
} else {
  senarai.add(jsonEncode(data));
}

final berjaya = await prefs.setStringList(
  'senarai_sebut_harga',
  senarai,
);

if (!berjaya) {
  throw StateError('Gagal menyimpan sebut harga');
}

if (widget.indeksEdit == null && modRujukan == 'auto') {
  final turutanSemasa =
      prefs.getInt('rujukan_turutan') ?? 1;

  final berjayaTurutan = await prefs.setInt(
    'rujukan_turutan',
    turutanSemasa + 1,
  );

  if (!berjayaTurutan) {
    throw StateError('Gagal mengemas kini nombor turutan');
  }
}

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
    rujukan.dispose();
    
    deposit.dispose();
    tempohSah.dispose();
    termaPembayaran.dispose();

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
          const SizedBox(height: 12),
          TextField(
            controller: rujukan,
            readOnly: modRujukan == 'auto',
            decoration: InputDecoration(
              labelText: 'No. Rujukan Sebut Harga',
              border: const OutlineInputBorder(),
              filled: modRujukan == 'auto',
              fillColor: modRujukan == 'auto'
                  ? Colors.grey.shade100
                  : null,
              suffixIcon: modRujukan == 'auto'
              ? const Icon(Icons.lock_outline)
              : null,
           ),
          ),
          
const SizedBox(height: 20),
const Text(
  'Terma Sebut Harga',
  style: TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.bold,
  ),
),
const SizedBox(height: 12),

medan('Deposit (%)', deposit, nombor: true),
const SizedBox(height: 12),

medan(
  'Tempoh Sah Sebut Harga (hari)',
  tempohSah,
  nombor: true,
),
const SizedBox(height: 12),

medan(
  'Terma & Syarat Pembayaran',
  termaPembayaran,
  maxLines: 4,
),

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
      
Navigator.of(this.context).pop(true);

    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        
SnackBar(
  content: Text(
    e is StateError
        ? e.message.toString()
        : 'Gagal menyimpan sebut harga',
  ),
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
