
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PelangganPage extends StatefulWidget {
  final Map<String, dynamic>? pelangganAsal;

  const PelangganPage({
    super.key,
    this.pelangganAsal,
  });

  @override

  State<PelangganPage> createState() => _PelangganPageState();
}

class _PelangganPageState extends State<PelangganPage> {
  final nama = TextEditingController();
  final syarikat = TextEditingController();
  final telefon = TextEditingController();
  final emel = TextEditingController();
  final alamat = TextEditingController();

  bool sedangSimpan = false;

@override
void initState() {
  super.initState();

  final asal = widget.pelangganAsal;

  if (asal != null) {
    nama.text = asal['nama']?.toString() ?? '';
    syarikat.text = asal['syarikat']?.toString() ?? '';
    telefon.text = asal['telefon']?.toString() ?? '';
    emel.text = asal['emel']?.toString() ?? '';
    alamat.text = asal['alamat']?.toString() ?? '';
  }
}

  Future<void> simpanPelanggan() async {
    if (sedangSimpan) return;

    if (nama.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sila masukkan nama pelanggan.'),
        ),
      );
      return;
    }

    setState(() {
      sedangSimpan = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final senarai = List<String>.from(
        prefs.getStringList('senarai_pelanggan') ?? [],
      );

      
final asal = widget.pelangganAsal;
final sekarang = DateTime.now();

final idAsal = asal?['id']?.toString();

final id = idAsal != null && idAsal.isNotEmpty
    ? idAsal
    : sekarang.microsecondsSinceEpoch.toString();

final pelangganBaru = <String, dynamic>{
  'id': id,
  'nama': nama.text.trim(),
  'syarikat': syarikat.text.trim(),
  'telefon': telefon.text.trim(),
  'emel': emel.text.trim(),
  'alamat': alamat.text.trim(),
  'tarikh': asal?['tarikh'] ??
      sekarang.toIso8601String(),
  'dikemaskini': sekarang.toIso8601String(),
};

if (asal != null) {
  final indeks = senarai.indexWhere((teks) {
    try {
      final rekod = jsonDecode(teks);

      return rekod is Map &&
          rekod['id']?.toString() == id;
    } catch (_) {
      return false;
    }
  });

  if (indeks < 0) {
    throw StateError(
      'Rekod pelanggan asal tidak ditemui.',
    );
  }

  senarai[indeks] = jsonEncode(pelangganBaru);
} else {
  senarai.add(jsonEncode(pelangganBaru));
}

      final berjaya = await prefs.setStringList(
        'senarai_pelanggan',
        senarai,
      );

      if (!berjaya) {
        throw StateError('Gagal menyimpan pelanggan.');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pelanggan berjaya disimpan.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal menyimpan pelanggan. Sila cuba lagi.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          sedangSimpan = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nama.dispose();
    syarikat.dispose();
    telefon.dispose();
    emel.dispose();
    alamat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pelanggan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'MAKLUMAT PELANGGAN',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF17345C),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Simpan maklumat pelanggan untuk '
            'digunakan dalam dokumen SebutPro MY.',
          ),

          const SizedBox(height: 20),

          TextField(
            controller: nama,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama Pelanggan *',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: syarikat,
            decoration: const InputDecoration(
              labelText: 'Nama Syarikat',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: telefon,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nombor Telefon',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: emel,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mel',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: alamat,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Alamat Pelanggan',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: sedangSimpan
                  ? null
                  : simpanPelanggan,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                sedangSimpan
                    ? 'Sedang Menyimpan...'
                    : 'Simpan Pelanggan',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF17345C),
                foregroundColor: Colors.white,
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
