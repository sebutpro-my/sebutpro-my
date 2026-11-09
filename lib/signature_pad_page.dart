
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignaturePadPage extends StatefulWidget {
  const SignaturePadPage({super.key});

  @override
  State<SignaturePadPage> createState() =>
      _SignaturePadPageState();
}

class _SignaturePadPageState
    extends State<SignaturePadPage> {
  late final SignatureController controller;

  @override
  void initState() {
    super.initState();

    controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  Future<void> simpanTandatangan() async {
    if (controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sila tandatangan terlebih dahulu',
          ),
        ),
      );
      return;
    }

    final Uint8List? gambar =
        await controller.toPngBytes();

    if (!mounted) return;

    if (gambar == null || gambar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal menyimpan tandatangan',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop(gambar);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tandatangan Digital'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Sila tandatangan menggunakan jari',
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                ),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(12),
                child: Signature(
                  controller: controller,
                  height: 260,
                  backgroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      controller.clear();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Padam'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: simpanTandatangan,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
