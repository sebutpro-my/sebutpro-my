# SEBUTPRO MY — BLUEPRINT V1.0
Tarikh: 6 November 2026
Status: Spesifikasi pembangunan awal

## 1. PENGENALAN
SebutPro MY ialah aplikasi mudah alih untuk kontraktor Malaysia menyediakan sebut harga, Bill of Quantities (BQ), invois dan rekod pembayaran.

Platform: Android dan iOS
Teknologi: Flutter, Supabase, GitHub dan Cloud Build
Bahasa: Bahasa Melayu (utama) dan English
Mata wang utama: Ringgit Malaysia (RM)

## 2. PENGGUNA SASARAN
Kontraktor kecil dan sederhana termasuk renovasi, pembinaan, awning, elektrik, plumbing, aircond, mengecat, landskap dan penyelenggaraan.

## 3. FORMAT DOKUMEN
A. Sebut Harga Ringkas
B. BQ Komersial
C. BQ Gaya JKR

Ketiga-tiga format menggunakan data asas yang sama tetapi susunan PDF berbeza. Templat gaya JKR ialah rujukan dan boleh disesuaikan; bukan pengesahan pematuhan rasmi JKR.

## 4. MODUL APLIKASI
- Akaun pengguna dan log masuk
- Mod percubaan tanpa pendaftaran
- Profil syarikat, logo, SSM dan maklumat bank
- Pengurusan pelanggan
- Pengurusan projek
- Sebut harga dan BQ berbilang seksyen
- Katalog huraian kerja
- Pengiraan automatik
- PDF Bahasa Melayu dan English
- Tandatangan elektronik kontraktor dan pelanggan
- Muat naik cop syarikat
- Invois, deposit, bayaran separa dan resit
- Rekod dan status dokumen
- Lampiran gambar projek
- Sandaran dan pemulihan data

## 5. FORMAT BQ KOMERSIAL
Maklumat syarikat dipaparkan di bahagian atas PDF.
Tajuk projek diletakkan di luar kotak maklumat sebagai perenggan tebal yang jelas.
Maklumat pelanggan, nombor rujukan dan tarikh diletakkan selepas tajuk.
Jadual BQ: Bil., Butiran Kerja, Unit, Kuantiti, Kadar (RM), Amaun (RM).
BQ menyokong seksyen A, B, C dan seterusnya.
Setiap seksyen mempunyai subtotal.
PDF mempunyai ringkasan harga, terma, maklumat bank pilihan, ruang tandatangan dan cop syarikat.
Dokumen panjang menggunakan beberapa halaman A4 dengan tajuk jadual berulang dan nombor halaman.

## 6. PERATURAN PENGIRAAN
Amaun item = Kuantiti x Kadar.
Jumlah seksyen = Jumlah amaun item dalam seksyen.
Jumlah dokumen = Jumlah seksyen selepas diskaun, caj dan cukai yang berkenaan.
Gunakan pengiraan perpuluhan tepat dan peraturan pembundaran yang konsisten.
SST tidak dikenakan secara automatik kepada semua pengguna.
Unit termasuk m, m2, m3, kaki2, No., set dan LS.

## 7. SEPULUH PENAMBAHBAIKAN
1. Nombor rujukan dokumen automatik dan unik.
2. Status serta sejarah dokumen.
3. Pindaan dokumen dengan nombor revisi.
4. Deposit dan bayaran berperingkat.
5. Resit pembayaran.
6. Diskaun, cukai dan pembundaran.
7. Gambar tapak dan lampiran.
8. Perlindungan tandatangan dan cop.
9. Sandaran serta pemulihan data.
10. Privasi, pemilikan dan pengasingan data.

## 8. DATABASE
Entiti utama:
- users / profiles
- companies
- company_memberships
- customers
- projects
- quotations
- quotation_sections
- quotation_items
- document_revisions
- work_catalog
- invoices
- invoice_items
- payments
- receipts
- signatures
- attachments
- document_templates
- audit_logs

Semua data perniagaan dihubungkan dengan company_id atau pemilikan setara.
Hubungan, constraints, indeks dan polisi RLS akan ditentukan dalam skema SQL berasingan.

## 9. TANDATANGAN DAN COP
Kontraktor boleh melukis atau memuat naik tandatangan.
Cop syarikat boleh dimuat naik sebagai imej.
Pelanggan boleh menandatangani pada peranti kontraktor.
Pengesahan jarak jauh dirancang untuk fasa berikutnya.
Simpan identiti, masa, versi dokumen dan bukti persetujuan.
Dokumen yang diterima tidak boleh diubah tanpa menghasilkan revisi baharu.
Tandatangan elektronik tidak semestinya tandatangan digital bersijil.

## 10. KESELAMATAN
- Supabase Authentication untuk akaun berdaftar.
- Row Level Security bagi semua jadual yang berkaitan.
- Pengasingan data antara syarikat.
- Penyimpanan fail sensitif dalam storan private.
- Kawalan akses bagi tandatangan, cop dan PDF.
- Tiada service-role key atau rahsia dalam aplikasi Flutter.
- Audit log bagi tindakan penting.
- Eksport dan pemadaman data mengikut polisi.
- Polisi privasi dan proses penghapusan akaun.
- Sandaran dan ujian pemulihan berkala.
- Mod tanpa daftar tidak menyimpan data sensitif ke cloud tanpa persetujuan dan kawalan yang sesuai.

## 11. ALIRAN PENGGUNA
Profil syarikat > Pelanggan > Projek > Pilih format > Masukkan BQ > Semak harga > Jana PDF > Tandatangan > Kongsi > Terima persetujuan > Invois > Bayaran > Resit.

## 12. STRATEGI PEMBANGUNAN
Fasa 1: GitHub dan POC Flutter percuma.
Fasa 2: Supabase, akaun dan keselamatan.
Fasa 3: Profil syarikat, pelanggan dan projek.
Fasa 4: Enjin BQ dan tiga templat.
Fasa 5: PDF, tandatangan, cop dan revisi.
Fasa 6: Invois, pembayaran dan resit.
Fasa 7: Ujian keselamatan dan pengguna.
Fasa 8: Google Play, kemudian Apple App Store.

## 13. CIRI MASA DEPAN
- Pengiraan kos dan margin keuntungan kontraktor.
- Pengurusan pekerja dan peranan lanjutan.
- AI membantu menyediakan huraian kerja.
- Integrasi harga bahan binaan.
- Templat PDF premium.
- Integrasi e-Invois LHDN jika dibangunkan dan disahkan berasingan.

## 14. PRINSIP PROJEK
Utamakan penggunaan telefon, kemudahan pengguna Malaysia, ketepatan pengiraan, keselamatan data, kos operasi terkawal dan kod yang boleh dipindahkan antara peranti.
Blueprint ini ialah spesifikasi awal, bukan bukti bahawa fungsi telah dibangunkan atau diuji.
