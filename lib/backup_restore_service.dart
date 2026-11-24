
import 'package:shared_preferences/shared_preferences.dart';

class BackupRestoreService {
  static const List<String> kunciUtama = [
    'profil_syarikat',
    'senarai_pelanggan',
    'senarai_bq',
    'senarai_sebut_harga',
    'senarai_invois',
    'rujukan_mod',
    'rujukan_awalan',
  ];

  static Future<bool> _simpan(
    SharedPreferences prefs,
    String kunci,
    Object nilai,
  ) async {
    if (nilai is String) {
      return prefs.setString(kunci, nilai);
    }
    if (nilai is List<String>) {
      return prefs.setStringList(kunci, nilai);
    }
    if (nilai is bool) {
      return prefs.setBool(kunci, nilai);
    }
    if (nilai is int) {
      return prefs.setInt(kunci, nilai);
    }
    if (nilai is double) {
      return prefs.setDouble(kunci, nilai);
    }

    throw FormatException(
      'Jenis data tidak disokong: $kunci',
    );
  }

  static Future<void> pulihkan(
    Map<String, dynamic> dataBackup,
  ) async {
    final Map<String, Object> dataDisahkan = {};

    // Sahkan semua data sebelum menyimpan.
    for (final entry in dataBackup.entries) {
      final rekod = entry.value;

      if (rekod is! Map<String, dynamic>) {
        throw FormatException(
          'Struktur tidak sah: ${entry.key}',
        );
      }

      final jenis = rekod['jenis'];
      final nilai = rekod['nilai'];

      Object data;

      switch (jenis) {
        case 'string':
          if (nilai is! String) {
            throw const FormatException('Teks tidak sah.');
          }
          data = nilai;
          break;

        case 'stringList':
          if (nilai is! List ||
              !nilai.every((item) => item is String)) {
            throw const FormatException('Senarai tidak sah.');
          }
          data = List<String>.from(nilai);
          break;

        case 'bool':
          if (nilai is! bool) {
            throw const FormatException('Boolean tidak sah.');
          }
          data = nilai;
          break;

        case 'int':
          if (nilai is! int) {
            throw const FormatException('Integer tidak sah.');
          }
          data = nilai;
          break;

        case 'double':
          if (nilai is! num) {
            throw const FormatException('Nombor tidak sah.');
          }
          data = nilai.toDouble();
          break;

        default:
          throw FormatException(
            'Jenis tidak dikenali: ${entry.key}',
          );
      }

      dataDisahkan[entry.key] = data;
    }

    for (final kunci in kunciUtama) {
      if (!dataDisahkan.containsKey(kunci)) {
        throw FormatException(
          'Data utama tiada: $kunci',
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();

    // Simpan nilai asal untuk percubaan pemulihan.
    final Map<String, Object?> dataAsal = {};

    for (final kunci in dataDisahkan.keys) {
      dataAsal[kunci] = prefs.get(kunci);
    }

    try {
      for (final entry in dataDisahkan.entries) {
        final berjaya = await _simpan(
          prefs,
          entry.key,
          entry.value,
        );

        if (!berjaya) {
          throw StateError(
            'Gagal menyimpan: ${entry.key}',
          );
        }
      }
    } catch (e) {
      // Cuba kembalikan nilai asal jika Restore gagal.
      bool rollbackBerjaya = true;

      for (final entry in dataAsal.entries) {
        try {
          final nilai = entry.value;
          final berjaya = nilai == null
              ? await prefs.remove(entry.key)
              : await _simpan(prefs, entry.key, nilai);

          if (!berjaya) {
            rollbackBerjaya = false;
          }
        } catch (_) {
          rollbackBerjaya = false;
        }
      }

      throw StateError(
        rollbackBerjaya
            ? 'Restore gagal. Nilai asal telah cuba '
                'dikembalikan. Sila semak rekod.'
            : 'Restore gagal dan sebahagian nilai asal '
                'mungkin tidak berjaya dikembalikan.',
      );
    }
  }
}
