# Campus Health App

Aplikasi direktori fasilitas kesehatan di sekitar kampus berbasis Flutter dengan peta, GPS, dan rute terintegrasi dengan cloud backend di Railway.

## Cara Clone dari GitHub (Untuk Anggota Kelompok)

### 1. Clone repositori

```bash
git clone https://github.com/username/campus-health-app.git
cd campus-health-app
```

Ganti `username` dengan nama organisasi/akun GitHub yang dipakai.

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Setup ORS API Key

Buka `lib/config.dart` dan isi API key:

```dart
class Config {
  static const String orsApiKey = 'API_KEY_ANDA';
}
```

> **Cara dapat API key**: daftar di https://openrouteservice.org/dev/#/signup (gratis, tanpa kartu kredit)

### 4. Jalankan

```bash
flutter run
```

Pilih Chrome/Edge untuk mode mobile simulator.

---

## Prerequisites

- **Flutter SDK** ^3.12.0 ([install guide](https://docs.flutter.dev/get-started/install))
- **Git** ([download](https://git-scm.com/downloads))
- **Backend API** sudah running di Railway (lihat repo `campus-health-api`)

## Step-by-step Init Flutter (Dari Awal)

### 1. Buat project

```bash
flutter create campus_health_app
cd campus_health_app
```

### 2. Tambahkan dependencies

```bash
flutter pub add http geolocator url_launcher flutter_map latlong2
```

| Package        | Versi   | Kegunaan                                                  |
| -------------- | ------- | --------------------------------------------------------- |
| `http`         | ^1.4.0  | Memanggil REST API backend & **OpenRouteService API**     |
| `geolocator`   | ^13.0.2 | Mendapatkan posisi GPS pengguna                           |
| `url_launcher` | ^6.3.1  | Membuka Google Maps eksternal untuk navigasi              |
| `flutter_map`  | ^7.0.2  | Menampilkan peta OSM (OpenStreetMap) gratis tanpa API key |
| `latlong2`     | ^0.9.1  | Tipe data LatLng untuk koordinat peta                     |

> **Catatan:** ORS API key digunakan untuk menggambar rute dan menghitung jarak/durasi perjalanan. Daftar gratis di https://openrouteservice.org/dev/#/signup lalu masukkan key ke `lib/config.dart`.

### 3. Struktur folder

Buat struktur folder manual:

```
lib/
├── main.dart                    # Entry point & tema
├── config.dart                  # Konfigurasi API key
├── models/
│   ├── category.dart            # Model kategori (RS/Klinik/Puskesmas)
│   └── place.dart               # Model tempat kesehatan
├── services/
│   └── api_service.dart         # HTTP client ke backend Railway
├── utils/
│   └── distance.dart            # Rumus Haversine (jarak GPS)
├── screens/
│   ├── home/
│   │   └── home_screen.dart     # Halaman utama grid kategori
│   ├── list/
│   │   └── list_screen.dart     # Daftar tempat per kategori
│   └── detail/
│       └── detail_screen.dart   # Detail + peta + rute
└── widgets/
    ├── category_card.dart       # Kartu kategori
    ├── place_card.dart          # Kartu tempat
    └── shimmer_loading.dart     # Loading shimmer animasi
```

### 4. Konfigurasi Android

Edit `android/app/src/main/AndroidManifest.xml` — tambahkan di dalam tag `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### 5. Konfigurasi iOS

Edit `ios/Runner/Info.plist` — tambahkan:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Aplikasi membutuhkan lokasi Anda untuk menampilkan jarak dan rute ke fasilitas kesehatan</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Aplikasi membutuhkan lokasi Anda untuk menampilkan jarak dan rute ke fasilitas kesehatan</string>
```

### 6. Siapkan ORS API Key

1. Daftar di https://openrouteservice.org/dev/#/signup
2. Dapatkan API key (gratis 2000 request/hari, tanpa kartu kredit)
3. Masukkan ke `lib/config.dart`:

```dart
class Config {
  static const String orsApiKey = 'API_KEY_ANDA';
}
```

### 7. Jalankan

```bash
flutter run
```

Pilih browser (Chrome/Edge) untuk mode mobile simulator.

## Arsitektur

```
┌─────────────────────┐       ┌──────────────────────────────┐
│  Flutter App (FE)   │  HTTP │  Railway Cloud Backend (BE)  │
│  - flutter_map      │◄─────►│  - Node.js / Express         │
│  - geolocator       │       │  - PostgreSQL                │
│  - ORS API (rute)   │       │  - REST API /api/places      │
└─────────────────────┘       └──────────────────────────────┘
         │
         ▼
  OpenRouteService API
  (rute driving-car)
```

## API Endpoints (Backend Railway)

| Method | Endpoint          | Keterangan                           |
| ------ | ----------------- | ------------------------------------ |
| GET    | `/api/categories` | Semua kategori                       |
| GET    | `/api/places`     | Semua tempat (opsional `?category=`) |
| GET    | `/api/places/:id` | Detail tempat                        |

Backend URL: `https://inspiring-gratitude-production-3d44.up.railway.app`

## Fitur

- **Direktori tempat**: lihat RS, Klinik, Puskesmas dari database
- **Peta OSM**: marker lokasi user + tempat tujuan
- **Jarak GPS**: hitung jarak lurus (Haversine) dari user ke setiap tempat
- **Rute navigasi**: gambar polyline rute via OpenRouteService + info jarak & durasi
- **Google Maps intent**: buka Google Maps eksternal untuk navigasi real-time
- **Travel mode**: pilih Mobil / Motor untuk rute

## Tema Warna

| Warna        | Kode      | Penggunaan                    |
| ------------ | --------- | ----------------------------- |
| Biru abu     | `#96B6C5` | Primary, AppBar, tombol       |
| Biru muda    | `#ADC4CE` | Secondary, kategori chip      |
| Krem         | `#EEE0C9` | Background kategori Puskesmas |
| Putih tulang | `#F1F0E8` | Scaffold background           |

## Learning Objectives

1. Cloud backend (Node.js/Express + PostgreSQL di Railway)
2. REST API (HTTP GET ke endpoint backend)
3. Database relasional (kategori & places)
4. Integrasi GPS & map (geolocator + flutter_map)
5. Deployment (Railway)
6. Demo dari HP (Flutter web atau APK)
