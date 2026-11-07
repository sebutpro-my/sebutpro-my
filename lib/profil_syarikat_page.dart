
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilSyarikatPage extends StatefulWidget {
  const ProfilSyarikatPage({super.key});

  @override
  State<ProfilSyarikatPage> createState() =>
      _ProfilSyarikatPageState();
}

class _ProfilSyarikatPageState
    extends State<ProfilSyarikatPage> {
  final nama = TextEditingController();
  final ssm = TextEditingController();
  final alamat = TextEditingController();
  final telefon = TextEditingController();
  final emel = TextEditingController();
  final bank = TextEditingController();
  final pemegangAkaun = TextEditingController();
  final nomborAkaun = TextEditingController();

  bool sedangMuat = true;
  bool sedangSimpan = false;

  static const kunciProfil = 'profil_syarikat';

  @override
  void initState() {
    super.initState();
    muatProfil();
  }

  Future<void> muatProfil() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final teks = prefs.getString(kunciProfil);

      if (teks != null) {
        final data = jsonDecode(teks);

        if (data is Map) {
          nama.text = data['nama']?.toString() ?? '';
          ssm.text = data['ssm']?.toString() ?? '';
          alamat.text = data['alamat']?.toString() ?? '';
          telefon.text = data['telefon']?.toString() ?? '';
          emel.text = data['emel']?.toString() ?? '';
          bank.text = data['bank']?.toString() ?? '';
          pemegangAkaun.text =
              data['pemegangAkaun']?.toString() ?? '';
          nomborAkaun.text =
              data['nomborAkaun']?.toString() ?? '';
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat profil syarikat'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => sedangMuat = false);
      }
    }
  }

  Future<void> simpanProfil() async {
    if (nama.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sila isi nama syarikat'),
        ),
      );
      return;
    }

    setState(() => sedangSimpan = true);

    try {
      final data = {
        'nama': nama.text.trim(),
        'ssm': ssm.text.trim(),
        'alamat': alamat.text.trim(),
        'telefon': telefon.text.trim(),
        'emel': emel.text.trim(),
        'bank': bank.text.trim(),
        'pemegangAkaun': pemegangAkaun.text.trim(),
        'nomborAkaun': nomborAkaun.text.trim(),
      };

      final prefs = await SharedPreferences.getInstance();
      final berjaya = await prefs.setString(
        kunciProfil,
        jsonEncode(data),
      );

      if (!berjaya) {
        throw StateError('Gagal menyimpan profil');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil syarikat berjaya disimpan'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan profil syarikat'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => sedangSimpan = false);
      }
    }
  }

  Widget medan(
    String label,
    TextEditingController controller, {
    TextInputType jenis = TextInputType.text,
    int baris = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: jenis,
        maxLines: baris,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nama.dispose();
    ssm.dispose();
    alamat.dispose();
    telefon.dispose();
    emel.dispose();
    bank.dispose();
    pemegangAkaun.dispose();
    nomborAkaun.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Syarikat'),
      ),
      body: sedangMuat
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Maklumat Syarikat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                medan('Nama Syarikat *', nama),
                medan('No. Pendaftaran SSM', ssm),
                medan(
                  'Alamat Syarikat',
                  alamat,
                  baris: 3,
                ),
                medan(
                  'No. Telefon',
                  telefon,
                  jenis: TextInputType.phone,
                ),
                medan(
                  'E-mel',
                  emel,
                  jenis: TextInputType.emailAddress,
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                const Text(
                  'Maklumat Pembayaran',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                medan('Nama Bank', bank),
                medan(
                  'Nama Pemegang Akaun',
                  pemegangAkaun,
                ),
                medan(
                  'Nombor Akaun',
                  nomborAkaun,
                  jenis: TextInputType.number,
                ),

                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed:
                      sedangSimpan ? null : simpanProfil,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    sedangSimpan
                        ? 'Sedang Menyimpan...'
                        : 'Simpan Profil Syarikat',
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  '* Nama syarikat wajib diisi.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
    );
  }
}
