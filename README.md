# OPTI - Aplikasi Optimalisasi Kinerja PC (PowerShell + WinForms)

**Copyright (c) H.MP Dev**  |  Pusat Developer: **https://hmp.my.id**

## Fitur

1. **Terms & Policy** - Wajib disetujui sebelum aplikasi berjalan. Jika tidak
   setuju, aplikasi menolak untuk dijalankan.
2. **Layanan & Fitur (Useless)** - Daftar semua layanan Windows dalam bentuk
   checkbox. Centang lalu klik "MATIKAN yang Dicentang". Layanan rekomendasi
   sudah ditandai otomatis.
3. **Optimasi Cepat (Registry)** - Nonaktifkan telemetri, iklan/Start, tips,
   Windows Error Reporting, dan efek visual, langsung dari registry.
4. **Pembersih Cache** - Memindai seluruh folder yang namanya mengandung
   "cache", lalu menghapus isinya. Plus: Temp Windows, Prefetch, Recycle Bin.
5. **RAM** - Kosongkan Standby List (RAM cache) dan Modified Page List lewat
   API sistem (butuh Administrator). Lihat info Total/Terpakai/Tersedia/Standby.
6. **Backup & Restore** - Otomatis menyimpan backup sebelum setiap perubahan;
   bisa dikembalikan kapan saja.

## Cara Menjalankan

**Cara 1 (disarankan):** klik 2x `run.bat`
- Aplikasi otomatis meminta izin Administrator (UAC) bila diperlukan.

## Hak Cipta & Pusat Developer

Opti dikembangkan oleh **H.MP Dev**. Kunjungi **https://hmp.my.id** untuk
info developer, update, dan proyek lainnya.

**Cara 2 - PowerShell:**
```
powershell -ExecutionPolicy Bypass -File "E:\Code\H.MP Dev\Opti\Opti.ps1"
```
- Tanpa izin admin, beberapa fitur (kosongkan RAM, ubah layanan) tidak akan
  bekerja. Opti akan menampilkan peringatan.

**Cara 3 - Satu baris dari internet**
```
irm https://raw.githubusercontent.com/HMPoetra/Opti/main/Opti.ps1 | iex
```
Langkah persiapan:
1. `$script:SourceUrl` pada `Opti.ps1` sudah menunjuk ke URL hosting tsb, jadi
   tidak perlu diedit lagi kecuali repositori Anda berpindah.
2. Jalankan perintah `irm https://raw.githubusercontent.com/HMPoetra/Opti/main/Opti.ps1 | iex`.
   Jika belum admin, Opti otomatis membuka jendela UAC lalu berjalan di sesi baru.
- Pada mode ini tidak ada file skrip lokal, jadi config disimpan di
  `%LOCALAPPDATA%\Opti\` (backup selalu di `Documents\BackupOpti`).
- Seluruh fitur lain (terms, layanan, cache, RAM, backup/restore) tetap sama.

> Butuh Windows 10/11 dan Administrator. Menggunakan tool ini berarti Anda
> menyetujui Terms & Policy di dalam aplikasi.

## Struktur Folder (dibuat otomatis saat pertama kali berjalan)

```
Opti\
  Opti.ps1       <- file utama (semua logika + UI)
  run.bat        <- launcher
  config.json    <- simpan status persetujuan (dibuat setelah setuju)
  Documents\BackupOpti   <- backup layanan & registry (JSON, otomatis dibuat di
                            folder Dokumen di setiap PC pemakai)
```

> Catatan: saat dijalankan via `irm ... | iex` (Cara 3), `config.json` mengarah
> ke `%LOCALAPPDATA%\Opti\`, tetapi backup selalu disimpan ke
> `Documents\BackupOpti` di setiap PC pemakai.

## Cara Memulihkan Pengaturan

Tab "Backup & Restore" > pilih file backup > "Load / Lihat Isi Backup" untuk
melihat isinya, atau "Restore Backup Terpilih" untuk mengembalikan.
Semua startup type layanan dan nilai registry dikembalikan sesuai backup.

## Hasil Pengujian (v1.4.0)

Pengujian menyeluruh dilakukan secara headless (tanpa menampilkan GUI) terhadap
`Opti.ps1` lengkap: seluruh fungsi dijalankan sungguhan pada sistem ini,
sedangkan operasi yang berisiko (hapus cache asli, ubah layanan, write
registry) diuji pada folder/isian sintetis di folder TEMP.

| # | Pengujian | Hasil | Keterangan |
|---|-----------|-------|------------|
| 1 | Parse skrip (PowerShell Parser) | `PASS` | Tidak ada error sintaks |
| 2 | Build GUI + 5 tab | `PASS` | Layanan, Registry, Cache, RAM, Backup |
| 3 | Grid daftar layanan | `PASS` | 300 layanan, 6 kolom |
| 4 | Centang rekomendasi otomatis | `PASS` | 27 layanan ditandai otomatis |
| 5 | Tombol "Centang Semua Rekomendasi" | `PASS` | Memilih 27 layanan |
| 6 | Tombol "Bersihkan Centang" | `PASS` | Semua centang dihapus |
| 7 | Info RAM (`Get-OptiRamInfo`) | `PASS` | Total 15.9 GB; free & standby terbaca |
| 8 | Tombol "Segarkan Info RAM" | `PASS` | Label ter-update (handler aktif) |
| 9 | Overlay loading (show/hide) | `PASS` | Muncul & hilang normal, tidak menghalangi |
| 10 | Snapshot registry (baca) | `PASS` | 7 tweak terbaca |
| 11 | Backup otomatis JSON | `PASS` | File dibuat di folder backup |
| 12 | Restore backup (uji aman/minimal) | `PASS` | 0 layanan gagal dikembalikan |
| 13 | Ukur ukuran folder cache | `PASS` | File 4096 byte terbaca |
| 14 | Pembersih cache (folder buatan) | `PASS` | Seluruh isi terhapus |
| 15 | Status folder cache hilang | `PASS` | Ditampilkan "Tidak Ada" |
| 16 | Status folder berhasil dibersihkan | `PASS` | Ditampilkan "Dibersihkan" |
| 17 | Enum cache seluruh sistem (baca) | `PASS` | 1454 folder cache terdeteksi |
| 18 | Link hak cipta di header GUI | `PASS` | Teks & URL "hmp.my.id" tampil |
| 19 | Kompilasi komponen RAM (C# native) | `PASS` | API termuat, diagnosa berfungsi |
| 20 | Konten ASCII-only | `PASS` | 0 byte non-ASCII (aman PS 5.1) |
| 21 | Tidak ada sisa "RAMMap" | `PASS` | Fitur/label RAMMap dihapus total |
| 22 | Persistensi config mode `irm | iex` (folder baru) | `PASS` | Folder `%LOCALAPPDATA%\Opti\` + `config.json` dibuat otomatis, roundtrip OK |

## Catatan Keamanan

- Aplikasi 100% lokal, tanpa internet, tanpa telemetri.
- Backup otomatis dibuat sebelum setiap perubahan.
- Folder cache hanya isinya yang dihapus, folder itu sendiri tetap ada.
- File yang sedang dipakai proses lain dilewati secara aman.
