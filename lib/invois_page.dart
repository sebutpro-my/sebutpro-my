
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'pilih_pelanggan_page.dart';

class InvoisPage extends StatefulWidget {
  final Map<String, dynamic>? invoisAsal;
  final Map<String, dynamic>? sebutHargaAsal;

  const InvoisPage({
    super.key,
    this.invoisAsal,
    this.sebutHargaAsal,
  });

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
  Map<String, dynamic>? maklumatPelanggan;
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

bool sedangSimpan = false;

@override
void initState() {
  super.initState();

final sebutHarga = widget.sebutHargaAsal;

if (sebutHarga != null && widget.invoisAsal == null) {
  pelanggan.text =
      sebutHarga['pelanggan']?.toString() ?? '';

  tajuk.text =
      sebutHarga['tajuk']?.toString() ?? '';

  final maklumatAsal =
      sebutHarga['maklumat_pelanggan'];

  if (maklumatAsal is Map) {
    maklumatPelanggan =
        Map<String, dynamic>.from(maklumatAsal);
  }

  final itemAsal = sebutHarga['items'];

  if (itemAsal is List && itemAsal.isNotEmpty) {
    for (final item in items) {
      item.dispose();
    }
    items.clear();

    for (final rekod in itemAsal) {
      if (rekod is! Map) continue;

      final item = _ItemInvois();

      item.butiran.text =
          rekod['butiran']?.toString() ?? '';
      item.kuantiti.text =
          rekod['kuantiti']?.toString() ?? '';
      item.kadar.text =
          rekod['kadar']?.toString() ?? '';

      final unitAsal =
          rekod['unit']?.toString() ?? 'unit';

      item.unit = units.contains(unitAsal)
          ? unitAsal
          : 'unit';

      items.add(item);
    }

    if (items.isEmpty) {
      items.add(_ItemInvois());
    }
  }
}

  final data = widget.invoisAsal;

  if (data == null) return;

  nomborInvois.text =
      data['nombor_invois']?.toString() ?? '';

  pelanggan.text =
      data['pelanggan']?.toString() ?? '';

final maklumatAsal = data['maklumat_pelanggan'];

if (maklumatAsal is Map) {
  maklumatPelanggan =
      Map<String, dynamic>.from(maklumatAsal);
}

  tajuk.text =
      data['tajuk']?.toString() ?? '';

  final itemAsal = data['items'];

  if (itemAsal is List && itemAsal.isNotEmpty) {
    for (final item in items) {
      item.dispose();
    }

    items.clear();

    for (final rekod in itemAsal) {
      if (rekod is! Map) continue;

      final item = _ItemInvois();

      item.butiran.text =
          rekod['butiran']?.toString() ?? '';

      item.kuantiti.text =
          rekod['kuantiti']?.toString() ?? '';

      item.kadar.text =
          rekod['kadar']?.toString() ?? '';

      final unitAsal =
          rekod['unit']?.toString() ?? 'unit';

      item.unit = units.contains(unitAsal)
          ? unitAsal
          : 'unit';

      items.add(item);
    }

    if (items.isEmpty) {
      items.add(_ItemInvois());
    }
  }
}
  
Future<void> simpanInvois() async {
  if (sedangSimpan) return;

  if (nomborInvois.text.trim().isEmpty ||
      pelanggan.text.trim().isEmpty ||
      tajuk.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sila lengkapkan nombor invois, pelanggan dan tajuk kerja.',
        ),
      ),
    );
    return;
  }

  if (items.any((item) =>
      item.butiran.text.trim().isEmpty ||
      (double.tryParse(item.kuantiti.text.trim()) ?? 0) <= 0 ||
      (double.tryParse(item.kadar.text.trim()) ?? -1) < 0)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sila semak butiran, kuantiti dan kadar item kerja.',
        ),
      ),
    );
    return;
  }

  setState(() => sedangSimpan = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final senarai = prefs.getStringList('senarai_invois') ?? [];

    final rujukan = nomborInvois.text.trim();

    
final invoisAsal = widget.invoisAsal;
final idAsal = invoisAsal?['id']?.toString();

if (invoisAsal != null &&
    (idAsal == null || idAsal.isEmpty)) {
  throw StateError(
    'ID invois asal tidak sah.',
  );
}

for (final teks in senarai) {
  final rekod = jsonDecode(teks);

  if (rekod is! Map) continue;

  // Abaikan invois sendiri semasa menyemak pendua.
  if (idAsal != null &&
      rekod['id']?.toString() == idAsal) {
    continue;
  }

  if (rekod['nombor_invois']
          ?.toString()
          .trim()
          .toLowerCase() ==
      rujukan.toLowerCase()) {
    throw StateError(
      'Nombor invois ini telah digunakan.',
    );
  }
}

final sumber = widget.sebutHargaAsal;

if (invoisAsal == null && sumber != null) {
  final idSumber =
      sumber['id']?.toString().trim() ?? '';
  final rujukanSumber =
      sumber['rujukan']?.toString().trim() ?? '';

  final invoisBerkaitan = <String>[];

  for (final teks in senarai) {
    final rekod = jsonDecode(teks);
    if (rekod is! Map) continue;

    final idRekod =
        rekod['id_sebut_harga_asal']
            ?.toString().trim() ?? '';
    final rujukanRekod =
        rekod['rujukan_sebut_harga']
            ?.toString().trim() ?? '';

    final samaId = idSumber.isNotEmpty &&
        idRekod.isNotEmpty &&
        idSumber == idRekod;
    
    final samaRujukan =
        rujukanSumber.isNotEmpty &&
        rujukanRekod.isNotEmpty &&
        rujukanSumber.toLowerCase() ==
            rujukanRekod.toLowerCase();

    if (samaId || samaRujukan) {
      invoisBerkaitan.add(
        rekod['nombor_invois']
            ?.toString() ?? 'Tanpa nombor',
      );
    }
  }

if (mounted) {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Diagnostik Invois'),
      content: Text(
        'ID Sebut Harga: $idSumber\n'
        'Rujukan Sebut Harga: $rujukanSumber\n'       
        'Kunci data sumber: ${sumber.keys.join(', ')}\n'
        'Bilangan invois berkaitan: '
        '${invoisBerkaitan.length}\n'
        'Jumlah rekod invois: ${senarai.length}',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}

  if (invoisBerkaitan.isNotEmpty) {
    if (!mounted) return;

    final teruskan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Sebut Harga Sudah Mempunyai Invois',
        ),
        content: Text(
          'Invois berkaitan:\n'
          '${invoisBerkaitan.join(', ')}\n\n'
          'Adakah anda mahu menghasilkan '
          'invois baharu daripada Sebut Harga '
          'yang sama?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Teruskan'),
          ),
        ],
      ),
    );

    if (teruskan != true) {
      if (mounted) {
        setState(() => sedangSimpan = false);
      }
      return;
    }

    if (!mounted) return;
  }
}

    final data = {
      
      'id': idAsal ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      'nombor_invois': rujukan,
 
      'rujukan_sebut_harga':
          invoisAsal?['rujukan_sebut_harga'] ??
          widget.sebutHargaAsal?['rujukan'],

      'id_sebut_harga_asal':
          invoisAsal?['id_sebut_harga_asal'] ??
          widget.sebutHargaAsal?['id'],
         
      'pelanggan': pelanggan.text.trim(),
      
'maklumat_pelanggan':
    maklumatPelanggan != null &&
            pelanggan.text.trim() ==
                (maklumatPelanggan!['nama']?.toString().trim() ?? '')
        ? Map<String, dynamic>.from(maklumatPelanggan!)
        : null,
'tajuk': tajuk.text.trim(),
      'tarikh': invoisAsal?['tarikh'] ??
          DateTime.now().toIso8601String(),
      'items': items.map((item) => {
        'butiran': item.butiran.text.trim(),
        'unit': item.unit,
        'kuantiti': item.kuantiti.text.trim(),
        'kadar': item.kadar.text.trim(),
      }).toList(),
      'jumlah': jumlahKeseluruhan,
      'status': invoisAsal?['status'] ?? 'Belum Bayar',
    };
 
if (invoisAsal == null) {
  // Invois baharu.
  senarai.add(jsonEncode(data));
} else {
  // Cari invois asal menggunakan ID.
  final indexAsal = senarai.indexWhere((teks) {
    final rekod = jsonDecode(teks);

    return rekod is Map &&
        rekod['id']?.toString() == idAsal;
  });

  if (indexAsal == -1) {
    throw StateError(
      'Rekod invois asal tidak dijumpai.',
    );
  }

final rekodTerkini = Map<String, dynamic>.from(
  jsonDecode(senarai[indexAsal]) as Map,
);

final bayaranAsal = rekodTerkini['rekod_bayaran'];
final senaraiBayaran =
    bayaranAsal is List ? bayaranAsal : <dynamic>[];

int jumlahDibayarSen = 0;

for (final bayaran in senaraiBayaran) {
  if (bayaran is Map) {
    final nilai = bayaran['jumlah'];
    final amaun = nilai is num
        ? nilai.toDouble()
        : double.tryParse(
              nilai.toString().replaceAll(',', '').trim(),
            ) ??
            0;

    if (!amaun.isFinite || amaun < 0) {
      throw StateError(
        'Rekod pembayaran tidak sah.',
      );
    }

    jumlahDibayarSen += (amaun * 100).round();
  }
}

final jumlahBaharuSen =
    (jumlahKeseluruhan * 100).round();

if (jumlahBaharuSen < jumlahDibayarSen) {
  throw StateError(
    'Jumlah invois tidak boleh kurang daripada '
    'jumlah bayaran yang telah diterima.',
  );
}

// Kekalkan rekod pembayaran dan maklumat asal.
data['rekod_bayaran'] = senaraiBayaran;
data['id'] = rekodTerkini['id'];
data['tarikh'] = rekodTerkini['tarikh'];

final bakiSen = jumlahBaharuSen - jumlahDibayarSen;

data['status'] = jumlahDibayarSen <= 0
    ? 'Belum Bayar'
    : bakiSen > 0
        ? 'Bayar Sebahagian'
        : 'Selesai Bayar';

// Kemas kini invois asal tanpa menghasilkan pendua.
senarai[indexAsal] = jsonEncode(data);

}

    final berjaya = await prefs.setStringList(
      'senarai_invois',
      senarai,
    );

    if (!berjaya) {
      throw StateError('Gagal menyimpan invois.');
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invois berjaya disimpan.'),
      ),
    );

    Navigator.of(context).pop(true);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e is StateError
              ? e.message.toString()
              : 'Gagal menyimpan invois.',
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() => sedangSimpan = false);
    }
  }
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
          
const SizedBox(height: 8),

OutlinedButton.icon(
  onPressed: () async {
    final dipilih =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const PilihPelangganPage(),
      ),
    );

    if (!mounted || dipilih == null) return;

    setState(() {
      maklumatPelanggan =
          Map<String, dynamic>.from(dipilih);

      pelanggan.text =
          dipilih['nama']?.toString() ?? '';
    });
  },
  icon: const Icon(Icons.contact_page_outlined),
  label: const Text('Pilih Pelanggan Tersimpan'),
),

const SizedBox(height: 12),
          
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
        
ElevatedButton.icon(
  onPressed: sedangSimpan ? null : simpanInvois,
  icon: const Icon(Icons.save_outlined),
  
label: Text(
  sedangSimpan
      ? 'Sedang Menyimpan...'
      : widget.invoisAsal != null
          ? 'Simpan Perubahan'
          : 'Simpan Invois',
),
),

const SizedBox(height: 24),
],
      ),
    );
  }
}
