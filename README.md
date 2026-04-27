# Assignment Deadline Tracker

Aplikasi mobile berbasis Flutter untuk membantu mahasiswa mencatat, melacak, dan mendapat pengingat deadline tugas kuliah. Data tersimpan secara real-time di cloud menggunakan Firebase, sehingga dapat diakses dari mana saja.

---

## Fitur Utama

### Autentikasi
- Register akun baru dengan nama, email, dan password
- Login dengan email dan password
- Fitur lupa password (kirim email reset)
- Logout dari akun
- Routing otomatis berdasarkan status login (Firebase Auth)

### Manajemen Mata Kuliah
- Tambah, edit, dan hapus mata kuliah
- Setiap mata kuliah memiliki nama, kode, dan warna identitas (8 pilihan warna)
- Menghapus mata kuliah otomatis menghapus semua tugas terkait

### Manajemen Tugas
- Tambah tugas dengan detail: judul, deskripsi, mata kuliah, deadline (tanggal & jam), prioritas, dan foto lampiran
- Edit semua detail tugas yang sudah ada
- Hapus tugas dengan konfirmasi dialog
- Prioritas tugas: **Low**, **Medium**, **High**
- Lampiran foto langsung dari kamera

### Tampilan & Interaksi
- Daftar tugas pending diurutkan berdasarkan deadline terdekat
- Filter tugas berdasarkan mata kuliah (chip filter horizontal)
- **Countdown badge** berwarna: hijau (aman), oranye (< 24 jam), merah (overdue)
- **Swipe kanan** kartu untuk mark as done (dengan opsi Undo)
- **Swipe kiri** kartu untuk menghapus tugas
- Halaman detail tugas lengkap dengan semua informasi

### Riwayat Tugas
- Daftar semua tugas yang sudah selesai
- Judul tugas ditampilkan dengan efek strikethrough
- Kembalikan tugas ke status pending (Restore)
- Hapus tugas dari riwayat secara permanen

### Notifikasi
- Notifikasi pengingat otomatis dijadwalkan 60 menit sebelum deadline
- Notifikasi dibatalkan otomatis saat tugas ditandai selesai atau dihapus
- Notifikasi diperbarui saat deadline tugas diedit

---

## Teknologi yang Digunakan

| Komponen | Teknologi |
|---|---|
| Framework | Flutter |
| Autentikasi | Firebase Authentication |
| Database | Cloud Firestore (real-time stream) |
| Notifikasi | Awesome Notifications |
| State Management | Provider + StreamBuilder |
| Kamera | image_picker |
| UI Design | Material Design 3 |

---

## Struktur Proyek

```
lib/
├── main.dart                        # Entry point, inisialisasi Firebase & routing auth
├── firebase_options.dart            # Konfigurasi Firebase
├── models/
│   ├── assignment.dart              # Model data tugas (Assignment)
│   └── course.dart                  # Model data mata kuliah (Course)
├── services/
│   ├── auth_service.dart            # Login, register, logout, reset password
│   ├── firestore_service.dart       # CRUD tugas & mata kuliah ke Firestore
│   └── notification_service.dart   # Jadwal & batalkan notifikasi
└── screens/
    ├── login_screen.dart            # Halaman login
    ├── register_screen.dart         # Halaman registrasi
    ├── main_scaffold.dart           # Bottom navigation (Assignments, History, Courses)
    ├── home_screen.dart             # Daftar tugas pending + filter
    ├── add_assignment_screen.dart   # Form tambah tugas baru
    ├── assignment_detail_screen.dart # Detail lengkap satu tugas
    ├── edit_assignment_screen.dart  # Form edit tugas
    ├── history_screen.dart          # Riwayat tugas selesai
    └── course_screen.dart           # Manajemen mata kuliah
```

---

## Cara Menjalankan

1. Clone repositori ini
2. Jalankan `flutter pub get` untuk menginstal dependencies
3. Pastikan sudah mengonfigurasi Firebase project dan file `google-services.json` ada di folder `android/app/`
4. Jalankan dengan `flutter run`

---

## Screenshot Alur Aplikasi

| Login | Home | Add Assignment |
|---|---|---|
| Form login dengan validasi | Daftar tugas + filter matkul | Form lengkap dengan foto & prioritas |

| Course | History | Detail |
|---|---|---|
| Kelola matkul dengan warna | Riwayat tugas selesai | Detail tugas + countdown |
