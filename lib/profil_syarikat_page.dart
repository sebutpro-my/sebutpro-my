
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

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
  
Uint8List? logoSyarikat;
Uint8List? copSyarikat;

final ImagePicker pemilihImej = ImagePicker();

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
        
final teksLogo = data['logo_syarikat']?.toString();

if (teksLogo != null && teksLogo.isNotEmpty) {
  try {
    logoSyarikat = base64Decode(teksLogo);
  } on FormatException {
    logoSyarikat = null;
  }
}

final teksCop = data['cop_syarikat']?.toString();

if (teksCop != null && teksCop.isNotEmpty) {
  try {
    copSyarikat = base64Decode(teksCop);
  } on FormatException {
    copSyarikat = null;
  }
}
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
  
Future<void> pilihImej({
  required bool logo,
}) async {
  try {
    final XFile? fail = await pemilihImej.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 70,
    );

    if (fail == null) return;

    final bytes = await fail.readAsBytes();

    if (!mounted) return;

    if (bytes.length > 500 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Imej terlalu besar. Sila pilih gambar lebih kecil.',
          ),
        ),
      );
      return;
    }

    setState(() {
      if (logo) {
        logoSyarikat = bytes;
      } else {
        copSyarikat = bytes;
      }
    });
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal memilih imej: $e'),
      ),
    );
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
      
'logo_syarikat': logoSyarikat == null
    ? null
    : base64Encode(logoSyarikat!),

'cop_syarikat': copSyarikat == null
    ? null
    : base64Encode(copSyarikat!),
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

Navigator.of(context).pop(true);

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
                
const SizedBox(height: 16),

const Text(
  'Logo & Cop Syarikat',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 12),

const Text(
  'Logo Syarikat',
  style: TextStyle(fontWeight: FontWeight.bold),
),

const SizedBox(height: 8),

if (logoSyarikat != null) ...[
  Image.memory(
    logoSyarikat!,
    height: 100,
    width: double.infinity,
    fit: BoxFit.contain,
  ),
  const SizedBox(height: 8),
],

OutlinedButton.icon(
  onPressed: () => pilihImej(logo: true),
  icon: const Icon(Icons.image_outlined),
  label: Text(
    logoSyarikat == null
        ? 'Pilih Logo Syarikat'
        : 'Tukar Logo Syarikat',
  ),
),

if (logoSyarikat != null)
  TextButton.icon(
    onPressed: () {
      setState(() {
        logoSyarikat = null;
      });
    },
    icon: const Icon(Icons.delete_outline),
    label: const Text('Padam Logo'),
  ),

const SizedBox(height: 20),

const Text(
  'Cop Syarikat',
  style: TextStyle(fontWeight: FontWeight.bold),
),

const SizedBox(height: 8),

if (copSyarikat != null) ...[
  Image.memory(
    copSyarikat!,
    height: 100,
    width: double.infinity,
    fit: BoxFit.contain,
  ),
  const SizedBox(height: 8),
],

OutlinedButton.icon(
  onPressed: () => pilihImej(logo: false),
  icon: const Icon(Icons.image_outlined),
  label: Text(
    copSyarikat == null
        ? 'Pilih Cop Syarikat'
        : 'Tukar Cop Syarikat',
  ),
),

if (copSyarikat != null)
  TextButton.icon(
    onPressed: () {
      setState(() {
        copSyarikat = null;
      });
    },
    icon: const Icon(Icons.delete_outline),
    label: const Text('Padam Cop'),
  ),

const SizedBox(height: 20),


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
