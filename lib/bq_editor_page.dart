
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'senarai_bq_page.dart';

class BqEditorPage extends StatefulWidget {
  final String format;
  final Map<String, dynamic>? bqAsal;

  const BqEditorPage({
    super.key,
    required this.format,
    this.bqAsal,
  });

  @override
  State<BqEditorPage> createState() =>
      _BqEditorPageState();
}

class _BqEditorPageState extends State<BqEditorPage> {
  final namaBahagian = TextEditingController();

  final tajukProjek = TextEditingController();

  final List<Map<String, dynamic>> bahagian = [];

  int nomborBahagian = 0;
  String? idBqSemasa;
  String? tarikhBqSemasa;
  
@override
void initState() {
  super.initState();

  final asal = widget.bqAsal;
  if (asal == null) return;

  idBqSemasa = asal['id']?.toString();
  tarikhBqSemasa = asal['tarikh']?.toString();

  tajukProjek.text = asal['tajuk']?.toString() ?? '';

  final dataBahagian = asal['bahagian'];

  if (dataBahagian is List) {
    for (final data in dataBahagian) {
      if (data is! Map) continue;

      final bahagianAsal =
          Map<String, dynamic>.from(data);

      final itemAsal = bahagianAsal['items'];
      final items = <Map<String, dynamic>>[];

      if (itemAsal is List) {
        for (final item in itemAsal) {
          if (item is Map) {
            items.add(Map<String, dynamic>.from(item));
          }
        }
      }

      final id = bahagianAsal['id'];

      if (id is int && id > nomborBahagian) {
        nomborBahagian = id;
      }

      bahagian.add({
        ...bahagianAsal,
        'items': items,
      });
    }
  }
}
  
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

Future<void> editItem(
  int idBahagian,
  int indexItem,
) async {
  final indexBahagian = bahagian.indexWhere(
    (b) => b['id'] == idBahagian,
  );

  if (indexBahagian < 0) return;

  final senaraiItem =
      bahagian[indexBahagian]['items']
          as List<Map<String, dynamic>>;

  if (indexItem < 0 ||
      indexItem >= senaraiItem.length) {
    return;
  }

  final itemAsal = senaraiItem[indexItem];

  final butiran = TextEditingController(
    text: itemAsal['butiran'].toString(),
  );

  final kuantiti = TextEditingController(
    text: itemAsal['kuantiti'].toString(),
  );

  final kadar = TextEditingController(
    text: itemAsal['kadar'].toString(),
  );

  const units = [
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
  ];

  String unitDipilih =
      itemAsal['unit']?.toString() ?? 'm²';

  if (!units.contains(unitDipilih)) {
    unitDipilih = 'm²';
  }

  final dataBaharu =
      await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Item Kerja'),
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
                    items: units.map((unit) {
                      return DropdownMenuItem<String>(
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
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Sila masukkan maklumat '
                          'item yang sah.',
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
                child: const Text(
                  'Simpan Perubahan',
                ),
              ),
            ],
          );
        },
      );
    },
  );

  butiran.dispose();
  kuantiti.dispose();
  kadar.dispose();

  if (!mounted || dataBaharu == null) return;

  setState(() {
    final index = bahagian.indexWhere(
      (b) => b['id'] == idBahagian,
    );

    if (index < 0) return;

    final items = bahagian[index]['items']
        as List<Map<String, dynamic>>;

    if (indexItem >= 0 &&
        indexItem < items.length) {
      items[indexItem] = dataBaharu;
    }
  });
}

Future<void> padamItem(
  int idBahagian,
  int indexItem,
) async {
  final sah = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Padam Item Kerja?'),
      content: const Text(
        'Adakah anda pasti mahu memadam '
        'item kerja ini daripada BQ?',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext, true),
          child: const Text(
            'Padam',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  if (!mounted || sah != true) return;

  setState(() {
    final indexBahagian = bahagian.indexWhere(
      (item) => item['id'] == idBahagian,
    );

    if (indexBahagian < 0) return;

    final senaraiItem =
        bahagian[indexBahagian]['items']
            as List<Map<String, dynamic>>;

    if (indexItem >= 0 &&
        indexItem < senaraiItem.length) {
      senaraiItem.removeAt(indexItem);
    }
  });
}

double jumlahBahagian(
  Map<String, dynamic> dataBahagian,
) {
  final senaraiItem = dataBahagian['items'];

  if (senaraiItem is! List) return 0;

  double jumlah = 0;

  for (final item in senaraiItem) {
    if (item is! Map) continue;

    final nilai = item['jumlah'];

    if (nilai is num && nilai.isFinite) {
      jumlah += nilai.toDouble();
    }
  }

  return jumlah;
}

double jumlahKeseluruhanBQ() {
  double jumlah = 0;

  for (final dataBahagian in bahagian) {
    jumlah += jumlahBahagian(dataBahagian);
  }

  return jumlah;
}

String formatWang(double nilai) {
  final bahagianNombor = nilai.toStringAsFixed(2).split('.');

  final depan = bahagianNombor[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (padanan) => ',',
  );

  return 'RM $depan.${bahagianNombor[1]}';
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

Future<void> simpanBQ() async {
  final tajuk = tajukProjek.text.trim();

  if (tajuk.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sila masukkan tajuk projek.'),
      ),
    );
    return;
  }

  if (bahagian.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sila tambah sekurang-kurangnya satu bahagian kerja.',
        ),
      ),
    );
    return;
  }

  final adaItem = bahagian.any((b) {
    final items = b['items'];
    return items is List && items.isNotEmpty;
  });

  if (!adaItem) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sila tambah sekurang-kurangnya satu item kerja.',
        ),
      ),
    );
    return;
  }

  try {
    final prefs = await SharedPreferences.getInstance();

    final senarai = List<String>.from(
      prefs.getStringList('senarai_bq') ?? [],
    );

    final sekarang = DateTime.now();
    final id = idBqSemasa ??
        sekarang.microsecondsSinceEpoch.toString();

    final tarikh = tarikhBqSemasa ??
        sekarang.toIso8601String();

    final data = <String, dynamic>{
      'id': id,
      'tajuk': tajuk,
      'format': widget.format,
      'tarikh': tarikh,
      'dikemaskini': sekarang.toIso8601String(),
      'bahagian': jsonDecode(jsonEncode(bahagian)),
      'jumlah': jumlahKeseluruhanBQ(),
    };

    final index = senarai.indexWhere((teks) {
      try {
        final rekod = jsonDecode(teks);
        return rekod is Map &&
            rekod['id']?.toString() == id;
      } catch (_) {
        return false;
      }
    });

    if (index >= 0) {
      senarai[index] = jsonEncode(data);
    } else {
      senarai.add(jsonEncode(data));
    }

    final berjaya = await prefs.setStringList(
      'senarai_bq',
      senarai,
    );

    if (!berjaya) {
      throw StateError('Gagal menyimpan BQ.');
    }

    if (!mounted) return;

    setState(() {
      idBqSemasa = id;
      tarikhBqSemasa = tarikh;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('BQ berjaya disimpan.'),
      ),
    );
  
if (widget.bqAsal != null) {
  Navigator.pop(context, true);
} else {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => const SenaraiBqPage(),
    ),
  );
}
} catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Gagal menyimpan BQ. Sila cuba lagi.',
        ),
      ),
    );
  }
}

  @override
  void dispose() {
    namaBahagian.dispose();
    tajukProjek.dispose();
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
          
TextField(
  controller: tajukProjek,
  maxLines: 2,
  decoration: const InputDecoration(
    labelText: 'Tajuk Projek',
    hintText: 'Contoh: Kerja Menaik Taraf Surau',
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 20),
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
    child: Column(
      children: [
        ListTile(
          title: Text(
            '${kodBahagian(i)} — '
            '${bahagian[i]['nama']}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${(bahagian[i]['items'] as List).length} '
            'item kerja',
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

        for (int j = 0;
            j < (bahagian[i]['items'] as List).length;
            j++)
          ListTile(
            title: Text(
              '${kodBahagian(i)}${j + 1} — '
              '${bahagian[i]['items'][j]['butiran']}',
            ),
            subtitle: Text(
              '${bahagian[i]['items'][j]['kuantiti']} '
              '${bahagian[i]['items'][j]['unit']} × '
              'RM${(bahagian[i]['items'][j]['kadar'] as num).toStringAsFixed(2)}',
            ),
            
trailing: SizedBox(
  width: 145,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'RM${(bahagian[i]['items'][j]['jumlah'] as num).toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF17345C),
          ),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF17345C),
            ),
            tooltip: 'Edit Item',
            onPressed: () => editItem(
              bahagian[i]['id'] as int,
              j,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
            tooltip: 'Padam Item',
            onPressed: () => padamItem(
              bahagian[i]['id'] as int,
              j,
            ),
          ),
        ],
      ),
    ],
  ),
), 
),

        Padding(
          padding: const EdgeInsets.all(12),
          child: OutlinedButton.icon(
            onPressed: () => tambahItem(
              bahagian[i]['id'] as int,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Item'),
          ),
        ),
      
const Divider(),

Padding(
  padding: const EdgeInsets.all(12),
  child: Row(
    children: [
      Expanded(
        child: Text(
          'JUMLAH BAHAGIAN ${kodBahagian(i)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF17345C),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        formatWang(jumlahBahagian(bahagian[i])),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF17345C),
        ),
      ),
    ],
  ),
),

      ],
    ),
  ),

          const SizedBox(height: 16),
        
Card(
  color: const Color(0xFFE8EDF7),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RINGKASAN BQ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF17345C),
          ),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < bahagian.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${kodBahagian(i)} - ${bahagian[i]['nama']}',
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatWang(jumlahBahagian(bahagian[i])),
                ),
              ],
            ),
          ),
        const Divider(),
        Row(
          children: [
            const Expanded(
              child: Text(
                'JUMLAH KESELURUHAN BQ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF17345C),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatWang(jumlahKeseluruhanBQ()),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF17345C),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
),

const SizedBox(height: 20),

SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: simpanBQ,
    icon: const Icon(Icons.save_outlined),
    label: const Text('Simpan BQ'),
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
      ),
    ),
  ),
),

        ],
      ),
    );
  }
}
