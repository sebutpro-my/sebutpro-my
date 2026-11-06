
import 'package:flutter/material.dart';
import 'sebut_harga_page.dart';
import 'senarai_sebut_harga_page.dart';

void main() {
  runApp(const SebutProApp());
}

class SebutProApp extends StatelessWidget {
  const SebutProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SebutPro MY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF17345C),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF17345C),
        foregroundColor: Colors.white,
        title: const Text('SebutPro MY'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Selamat Datang!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Urus dokumen kontraktor dengan mudah.',
          ),
          const SizedBox(height: 24),
          _menu(
            context,
            Icons.description_outlined,
            'Sebut Harga',
            'Cipta sebut harga baharu',
          ),
          
          _menu(
            context,
            Icons.folder_open_outlined,
            'Senarai Sebut Harga',
            'Lihat sebut harga yang telah disimpan',
          ),
          _menu(
            context,
            Icons.calculate_outlined,
            'BQ Terperinci',
            'BQ Komersial dan format JKR',
          ),
          _menu(
            context,
            Icons.receipt_long_outlined,
            'Invois',
            'Urus invois pelanggan',
          ),
          _menu(
            context,
            Icons.people_outline,
            'Pelanggan',
            'Maklumat pelanggan dan projek',
          ),
          _menu(
            context,
            Icons.business_outlined,
            'Profil Syarikat',
            'Logo, alamat dan maklumat bank',
          ),
        ],
      ),
    );
  }

  Widget _menu(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Icon(
          icon,
          color: const Color(0xFF17345C),
          size: 30,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        
onTap: () {
  if (title == 'Sebut Harga') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SebutHargaPage(),
      ),
    );
  
} else if (title == 'Senarai Sebut Harga') {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const SenaraiSebutHargaPage(),
    ),
  );
} else {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title - Akan dibangunkan'),
      ),
    );
  }
},

      ),
    );
  }
}
