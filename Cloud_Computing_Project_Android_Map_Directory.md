# PROJECT CLOUD COMPUTING

## Android Map Directory

Aplikasi direktori berbasis peta untuk menemukan tempat di sekitar kampus dan membuka rute langsung dari HP.

**Komponen wajib:** Android • Server • REST API • Database • GPS • Map Routing

_Mata Kuliah Cloud Computing_

---

## Konteks Proyek

_Masalah nyata di sekitar kampus sebagai bahan latihan cloud computing_

### Ide Utama

Membangun aplikasi Android yang mengambil data direktori dari server cloud melalui API, menampilkan tempat pada peta, memakai GPS pengguna, dan membuka rute ke lokasi tujuan.

---

## Tujuan Pembelajaran

_Proyek dirancang untuk menguji pemahaman cloud secara aplikatif_

1. **Cloud Backend** — Mahasiswa menyiapkan server/API yang dapat diakses dari aplikasi Android melalui internet.
2. **REST API** — Aplikasi mobile tidak membaca database langsung, tetapi berkomunikasi melalui endpoint API.
3. **Database** — Data tempat, kategori, koordinat, rating, dan foto disimpan secara terstruktur di server.
4. **GPS & Map** — Aplikasi mengambil lokasi pengguna, menghitung jarak, menampilkan marker, dan membuka rute.
5. **Deployment** — Backend dipublikasikan agar benar-benar dapat dipanggil oleh HP, bukan hanya berjalan lokal.
6. **Demo End-to-End** — Hasil akhir harus dapat didemonstrasikan dari HP: cari tempat, lihat detail, dan buka rute.

> **Inti penilaian:** bukan hanya tampilan Android, tetapi integrasi antara mobile app, server cloud, API, database, dan GPS.

---

## Skenario Pengguna

_Alur paling sederhana yang harus berjalan pada aplikasi_

```
Buka aplikasi → Izinkan GPS → Pilih kategori / cari tempat → Lihat detail tempat → Buka rute
```

**Contoh use case:** mahasiswa baru mencari tempat nongkrong yang dekat, melihat estimasi jarak, lalu diarahkan ke aplikasi peta untuk navigasi.

**Minimum viable product:** daftar tempat + marker peta + detail + rute dari lokasi pengguna.

---

## Ruang Lingkup Fitur

_Fitur minimum dan fitur tambahan agar proyek terukur_

### Fitur Wajib

- **Direktori Tempat** — Daftar tempat berisi nama, kategori, alamat, koordinat, jam buka, deskripsi singkat.
- **Map & Marker** — Marker tempat ditampilkan pada peta berdasarkan data latitude dan longitude dari server.
- **GPS & Rute** — Aplikasi membaca lokasi pengguna dan membuka rute menuju tempat yang dipilih.

### Fitur Tambahan

- **Pencarian & Filter** — Filter berdasarkan kategori, jarak, rating, atau kata kunci.
- **Admin Input Data** — Halaman web sederhana untuk menambah atau mengedit data tempat.
- **Favorit / Review** — Pengguna dapat menyimpan tempat favorit atau memberi rating sederhana.

> **Saran:** batasi fitur agar integrasi cloud berjalan stabil sebelum menambah fitur kosmetik.

---

## Arsitektur Sistem

_Pemisahan tanggung jawab antara mobile app, API, cloud server, dan database_

```
Android App          REST API           Cloud Server        Database
(UI, GPS, Map)  ←→  (JSON over HTTPS)  ←→  (Backend Logic)  ←→  (Places, Categories, Reviews)
                                                   ↓
                                            Map Service
                                         (Routing / intent)
```

> **Prinsip penting:** aplikasi Android tidak langsung mengakses database. Semua data harus melewati API agar sistem aman, terkontrol, dan mudah dikembangkan.

---

## Pilihan Teknologi

_Mahasiswa boleh memilih stack, tetapi pola arsitekturnya tetap sama_

- **Android** — Kotlin/Java atau Flutter. Fitur utama: Map SDK, permission GPS, list tempat, detail tempat, dan intent untuk rute.
- **Backend API** — Node.js/Express, Laravel, CodeIgniter, Flask, atau FastAPI. Fokus pada endpoint yang stabil dan JSON response yang rapi.
- **Database** — Google Sheet, MySQL, PostgreSQL, Firebase, atau MongoDB. Minimal ada tabel/collection untuk tempat dan kategori.
- **Cloud Deployment** — Backend harus online. Bisa memakai GAS, VPS, cloud platform, hosting backend, atau layanan serverless sederhana.

---

## Desain API Minimum

_Endpoint sederhana yang cukup untuk menjalankan aplikasi_

| Method | Endpoint                    | Fungsi                                |
| ------ | --------------------------- | ------------------------------------- |
| GET    | `/api/places`               | Mengambil daftar semua tempat         |
| GET    | `/api/places?category=cafe` | Filter tempat berdasarkan kategori    |
| GET    | `/api/places/{id}`          | Mengambil detail satu tempat          |
| GET    | `/api/categories`           | Mengambil daftar kategori             |
| POST   | `/api/places`               | Opsional: tambah tempat melalui admin |

**Format respons disarankan:** JSON berisi `id`, `name`, `category`, `address`, `latitude`, `longitude`, `description`, `rating`, `photo_url`.

---

## Model Data Sederhana

_Struktur database yang memadai untuk direktori berbasis peta_

### `categories`

- `id`
- `name`
- `icon`

### `places` _(Minimal wajib)_

- `id`
- `category_id`
- `name`
- `lat`, `lng`
- `address`
- `description`

### `reviews / favorites`

- `id`
- `place_id`
- `user_id`
- `rating`
- `comment`

> **Catatan:** Koordinat latitude dan longitude adalah inti aplikasi. Tanpa koordinat, data tidak dapat ditampilkan sebagai marker dan tidak dapat digunakan untuk navigasi.

---

## GPS dan Routing

_Bagaimana aplikasi mengubah lokasi menjadi aksi navigasi_

1. **Request GPS Permission**
2. **Ambil User Location**
3. **Pilih Destination**
4. **Buka rute di aplikasi map**

Rute dapat dibuka melalui intent URL peta menggunakan koordinat tujuan dari database.

---

## Rancangan Tampilan Android

_Tiga layar utama sudah cukup untuk demo proyek_

| Home & Kategori                     | Peta & Marker                      | Detail & Rute                          |
| ----------------------------------- | ---------------------------------- | -------------------------------------- |
| Daftar kategori dan tempat terdekat | Marker tempat pada peta interaktif | Info lengkap tempat + tombol buka rute |

---

## Keamanan dan Kualitas Layanan

_Aspek cloud sederhana yang harus diperhatikan_

- **API Key & Credential** — Jangan menyimpan password database di aplikasi Android. Credential backend harus berada di server.
- **HTTPS** — Gunakan koneksi aman jika memungkinkan, terutama ketika aplikasi dipublikasikan dan diakses melalui internet.
- **Validasi Data** — Backend perlu memeriksa input agar data lokasi tidak kosong, koordinat valid, dan kategori sesuai.
- **Error Handling** — Android harus menampilkan pesan jika GPS mati, API gagal, internet tidak tersedia, atau data kosong.
- **Scalability Ringan** — Pisahkan app, API, dan database agar nanti mudah menambah fitur seperti review, admin, atau analitik.
- **Privacy GPS** — Lokasi pengguna cukup dipakai sementara untuk jarak/rute. Tidak perlu disimpan tanpa alasan yang jelas.

---

## Rencana Pengerjaan

_Tahapan kerja 5 minggu yang realistis untuk proyek kuliah_

| Tahap | Waktu        | Kegiatan                                                       |
| ----- | ------------ | -------------------------------------------------------------- |
| 1     | Minggu 1     | Definisi domain, fitur, data tempat, dan rancangan database.   |
| 2     | Minggu 2     | Bangun backend API dan uji endpoint dengan Postman/browser.    |
| 3     | Minggu 3 & 4 | Bangun UI Android: list, detail, peta, dan marker.             |
| 4     | Minggu 5 & 6 | Integrasi GPS, routing, error handling, dan deployment server. |
| 5     | Minggu 7     | Testing, dokumentasi, video/demo, dan presentasi akhir.        |

> Setiap minggu harus menghasilkan artefak: skema, API, app screen, integrasi, dan demo.

---

## Pengujian dan Demo

_Apa yang harus dibuktikan saat presentasi proyek_

- **Uji API** — Endpoint `/places`, `/categories`, dan `/places/{id}` berjalan dari jaringan luar dan memberi JSON yang benar.
- **Uji Data** — Minimal 15–30 tempat memiliki koordinat valid dan muncul sebagai marker pada peta.
- **Uji GPS** — Aplikasi meminta izin lokasi, membaca lokasi pengguna, dan tetap menangani kondisi GPS mati.
- **Uji Routing** — Saat satu tempat dipilih, aplikasi dapat membuka rute menuju koordinat tujuan.
- **Uji Koneksi** — Aplikasi memberi pesan yang jelas saat server down, internet mati, atau response kosong.
- **Demo Akhir** — Demo dilakukan dari HP/emulator: buka aplikasi, pilih tempat, lihat detail, dan jalankan rute.

---

## Output Akhir dan Penilaian

_Artefak yang dikumpulkan dan bobot penilaian yang disarankan_

| Bobot | Komponen                         | Kriteria                                                                         |
| ----- | -------------------------------- | -------------------------------------------------------------------------------- |
| 35%   | Aplikasi Android                 | UI berjalan, peta tampil, marker muncul, detail tempat jelas, rute dapat dibuka. |
| 25%   | Backend, API, & Cloud Deployment | Server online, endpoint rapi, response JSON benar, error ditangani.              |
| 15%   | Database & Data                  | Skema sesuai, koordinat valid, data cukup, kategori jelas.                       |
| 15%   | Dokumentasi & Demo               | Presentasi, diagram arsitektur, bukti testing, dan video/screenshot demo.        |
| 10%   | Dokumen HKI                      | Dokumen yang diperlukan untuk pendaftaran HKI.                                   |

> **Kesimpulan:** proyek berhasil bila aplikasi mobile, API, database, server cloud, dan GPS dapat bekerja sebagai satu sistem.
