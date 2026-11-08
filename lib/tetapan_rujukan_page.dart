
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TetapanRujukanPage extends StatefulWidget {
  const TetapanRujukanPage({super.key});

  @override
  State<TetapanRujukanPage> createState() =>
      _TetapanRujukanPageState();
}

class _TetapanRujukanPageState
    extends State<TetapanRujukanPage> {
  String mod = 'manual';

  final awalan = TextEditingController(
    text: 'SH/2026/',
  );

  final turutan = TextEditingController(
    text: '1',
  );

  bool sedangMuat = true;
  bool sedangSimpan = false;

  @override
  void initState() {
    super.initState();
    muatTetapan();
  }

  Future<void> muatTetapan() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      mod = prefs.getString('rujukan_mod') ?? 'manual';
      awalan.text =
          prefs.getString('rujukan_awalan') ?? 'SH/2026/';
      turutan.text =
          (prefs.getInt('rujukan_turutan') ?? 1).toString();
      sedangMuat = false;
    });
  }

  Future<void> simpanTetapan() async {
    final nombor = int.tryParse(turutan.text.trim());

    if (mod == 'auto' &&
        (awalan.text.trim().isEmpty ||
         nombor == null ||
         nombor < 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Isi awalan dan nombor turutan yang sah',
          ),
        ),
      );
      return;
    }

    setState(() => sedangSimpan = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      final a = await prefs.setString(
        'rujukan_mod',
        mod,
      );

      final b = await prefs.setString(
        'rujukan_awalan',
        awalan.text.trim(),
      );

      final c = await prefs.setInt(
        'rujukan_turutan',
        nombor ?? 1,
      );

      if (!a || !b || !c) {
        throw StateError('Gagal menyimpan tetapan');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tetapan rujukan berjaya disimpan'),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan tetapan rujukan'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => sedangSimpan = false);
      }
    }
  }

  @override
  void dispose() {
    awalan.dispose();
    turutan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tetapan Nombor Rujukan'),
      ),
      body: sedangMuat
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Kaedah Nombor Rujukan',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                RadioListTile<String>(
                  title: const Text('Manual'),
                  subtitle: const Text(
                    'Isi nombor rujukan sendiri',
                  ),
                  value: 'manual',
                  groupValue: mod,
                  onChanged: (nilai) {
                    if (nilai != null) {
                      setState(() => mod = nilai);
                    }
                  },
                ),

                RadioListTile<String>(
                  title: const Text('Automatik'),
                  subtitle: const Text(
                    'Gunakan format dan turutan syarikat',
                  ),
                  value: 'auto',
                  groupValue: mod,
                  onChanged: (nilai) {
                    if (nilai != null) {
                      setState(() => mod = nilai);
                    }
                  },
                ),

                if (mod == 'auto') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: awalan,
                    decoration: const InputDecoration(
                      labelText: 'Awalan Rujukan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: turutan,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nombor Turutan Seterusnya',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed:
                      sedangSimpan ? null : simpanTetapan,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    sedangSimpan
                        ? 'Sedang Menyimpan...'
                        : 'Simpan Tetapan',
                  ),
                ),
              ],
            ),
    );
  }
}
