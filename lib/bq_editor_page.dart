
import 'package:flutter/material.dart';

class BqEditorPage extends StatefulWidget {
  final String format;

  const BqEditorPage({
    super.key,
    required this.format,
  });

  @override
  State<BqEditorPage> createState() =>
      _BqEditorPageState();
}

class _BqEditorPageState extends State<BqEditorPage> {
  final namaBahagian = TextEditingController();

  final List<Map<String, dynamic>> bahagian = [];

  int nomborBahagian = 0;

  String kodBahagian(int nombor) {
    var nilai = nombor;
    var kod = '';

    do {
      kod = String.fromCharCode(
            65 + (nilai % 26),
          ) +
          kod;
      nilai = nilai ~/ 26 - 1;
    } while (nilai >= 0);

    return kod;
  }

  void tambahBahagian() {
    final nama = namaBahagian.text.trim();

    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sila masukkan nama bahagian kerja.',
          ),
        ),
      );
      return;
    }

    setState(() {
      bahagian.add({
        'id': ++nomborBahagian,
        'nama': nama,
        'items': <Map<String, dynamic>>[],
      });

      namaBahagian.clear();
    });
  }

Future<void> tambahItem(int idBahagian) async {
  final butiran = TextEditingController();
  final kuantiti = TextEditingController();
  final kadar = TextEditingController();

  String unitDipilih = 'm²';

  final dataItem =
      await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Tambah Item Kerja'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: butiran,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Butiran Kerja',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: unitDipilih,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      'unit',
                      'nos',
                      'm',
                      'm²',
                      'm³',
                      'kaki',
                      'kaki²',
                      'LS',
                      'set',
                      'kg',
                    ].map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (nilai) {
                      if (nilai != null) {
                        setDialogState(() {
                          unitDipilih = nilai;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: kuantiti,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Kuantiti',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: kadar,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Kadar (RM)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final qty = double.tryParse(
                    kuantiti.text.trim(),
                  );

                  final rate = double.tryParse(
                    kadar.text.trim(),
                  );

                  if (butiran.text.trim().isEmpty ||
                      qty == null ||
                      rate == null ||
                      !qty.isFinite ||
                      !rate.isFinite ||
                      qty <= 0 ||
                      rate < 0) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Sila lengkapkan butiran, '
                          'kuantiti dan kadar yang sah.',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    {
                      'butiran': butiran.text.trim(),
                      'unit': unitDipilih,
                      'kuantiti': qty,
                      'kadar': rate,
                      'jumlah': qty * rate,
                    },
                  );
                },
                child: const Text('Tambah'),
              ),
            ],
          );
        },
      );
    },
  );

  if (!mounted || dataItem == null) return;

  setState(() {
    final index = bahagian.indexWhere(
      (item) => item['id'] == idBahagian,
    );

    if (index >= 0) {
      final senaraiItem =
          bahagian[index]['items']
              as List<Map<String, dynamic>>;

      senaraiItem.add(dataItem);
    }
  });
}

  Future<void> padamBahagian(int id) async {
    final sah = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Padam Bahagian?'),
        content: const Text(
          'Bahagian ini akan dikeluarkan '
          'daripada BQ yang sedang disediakan.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Padam'),
          ),
        ],
      ),
    );

    if (!mounted || sah != true) return;

    setState(() {
      bahagian.removeWhere(
        (item) => item['id'] == id,
      );
    });
  }

  @override
  void dispose() {
    namaBahagian.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatJKR = widget.format == 'jkr';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          formatJKR ? 'BQ Gaya JKR' : 'BQ Komersial',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'BAHAGIAN KERJA',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Tambah bahagian kerja mengikut '
            'susunan BQ projek.',
          ),

          const SizedBox(height: 20),

          TextField(
            controller: namaBahagian,
            decoration: const InputDecoration(
              labelText: 'Nama Bahagian Kerja',
              hintText: 'Contoh: Kerja Awalan',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: tambahBahagian,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Bahagian'),
          ),

          const SizedBox(height: 20),

          if (bahagian.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Belum ada bahagian kerja. '
                  'Sila tambah bahagian pertama.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          for (int i = 0; i < bahagian.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  '${kodBahagian(i)} — '
                  '${bahagian[i]['nama']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  '0 item kerja',
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  onPressed: () => padamBahagian(
                    bahagian[i]['id'] as int,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          const Text(
            'Fungsi tambah item kerja dan simpan BQ '
            'akan dibina pada langkah seterusnya.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
