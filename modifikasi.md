# Modifikasi — 14 Juni 2026 (Sesi 1 & 2)

## Ringkasan

Sesi 1: Rebranding aplikasi dari **Campus Health** → **Healthy UNAIR**. Penambahan sistem navigasi (bottom nav, maps screen, turn-by-turn navigation dengan TTS), perombakan home screen, dan perubahan warna ke tema hijau.

Sesi 2: Stabilisasi layout home ke versi commit `585683d`, integrasi foto dari backend, penghapusan fitur Favorit, Indonesianisasi UI, perbaikan bug, dan tombol "Lihat Semua" yang berfungsi.

---

## File Baru

| File                                | Keterangan                                                                                                                                 |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `lib/screens/main_shell.dart`       | Bottom navigation shell (Home, Map, Favorites, Profile) dengan `IndexedStack`. Favorites & Profile menampilkan snackbar "Segera Hadir".    |
| `lib/screens/maps/maps_screen.dart` | Halaman peta interaktif dengan `flutter_map`, marker tempat kesehatan, filter kategori, lokasi user real-time, bottom sheet detail tempat. |

## File Dihapus

| File                                         | Keterangan                       |
| -------------------------------------------- | -------------------------------- |
| `lib/models/favorites_notifier.dart`         | Fitur Favorit dihapus total      |
| `lib/screens/favorite/favorites_screen.dart` | Halaman Favorit dihapus total    |
| `lib/screens/home/home_screen.dart.backup`   | File backup dari sesi sebelumnya |

## File Dimodifikasi

### `lib/main.dart`

**Sesi 1:**
- `CampusHealthApp` → `HealthyUnairApp`
- Tema diubah ke warna hijau (`#0D631B`) dengan `ColorScheme` lengkap
- Home → `MainShell`

**Sesi 2:**
- (tidak ada perubahan)

### `lib/screens/home/home_screen.dart`

**Sesi 1:**
- Redesain total dari layout kolom sederhana menjadi `CustomScrollView` + `SliverAppBar`
- Search bar dengan ikon + clear button
- Categories row (FutureBuilder, 3 chip: Rumah Sakit, Klinik, Puskesmas)
- Nearby Facilities horizontal scroll (FutureBuilder, card dengan image placeholder + rating)
- Recommended for You vertical list dengan info lengkap (address, rating, jam buka)
- Skeleton loading untuk semua state loading
- Tap category → `ListScreen`, tap place → `DetailScreen`

**Sesi 2:**
- Layout dikembalikan ke struktur asli commit `585683d`
- Semua teks di-Indonesianisasi: `"Hello, Student!"` → `"Halo, Mahasiswa!"`, `"Nearby Facilities"` → `"Fasilitas Terdekat"`, `"Recommended for You"` → `"Rekomendasi untuk Anda"`, dll.
- Tombol `"Lihat Semua"` → navigasi ke `ListScreen(showAll: true)` (sebelumnya `onPressed: () {}` kosong)
- Foto real-time dari backend di `_FacilityCard` (via `Image.network` + `place.effectiveFotoUrl`, fallback ke icon hospital)
- Foto real-time dari backend di `_RecommendedCard` (sama)
- Helper methods `_buildIconFallback()` dan `_buildRatingBadge()` untuk mengurangi duplikasi kode
- `___` → `_` fix pada parameter unused di `errorBuilder`
- Row overflow fixed: teks jam buka dibungkus `Expanded` + `maxLines: 1` + `TextOverflow.ellipsis`
- Import `list_screen.dart`

### `lib/screens/detail/detail_screen.dart`

**Sesi 1:**
- **Mode navigasi turn-by-turn**: tombol "Mulai Rute", navigation card dengan instruksi langkah, progress bar, ETA, tombol berhenti
- `FlutterTts` untuk voice instruction (import & instance)
- `_scale` factor untuk responsive UI
- Tombol "Mulai Rute" di info section dan route info card
- Route info card didesain ulang: layout wrap, tombol mulai rute, close button
- Warna diubah: `#96B6C5` → `#0D631B`, `#222222` → `#1B1C17`, dll.
- `_buildNavigationCard()` — widget baru untuk tampilan navigasi aktif
- `_stepIcon()`, `_showAllSteps()`, `_openNavigation()` — method baru
- `padding` dan `fontSize` menggunakan `_scale`

**Sesi 2:**
- Layout diubah: map di atas, info di tengah, foto di bawah (tanpa label "Foto")
- `setState` setelah `await` diberi guard `mounted` untuk cegah error `"setState() called after dispose()"`

### `lib/screens/list/list_screen.dart`

**Sesi 1:**
- Background: `#F1F0E8` → `#FBF9F1`
- AppBar: gradient `#96B6C5`/`#ADC4CE` → solid `#0D631B`
- Warna teks dan icon disesuaikan ke tema hijau

**Sesi 2:**
- `Category category` → `Category? category` (nullable)
- Tambah field `bool showAll = false`
- Jika `showAll == true`, panggil `_api.getPlaces()` tanpa filter kategori
- Title AppBar: `"Semua Fasilitas"` jika `showAll`

### `lib/screens/main_shell.dart`

**Sesi 1:**
- Bottom navigation shell (`IndexedStack`)
- 4 screen: Home, Map, Favorites, Profile
- `withOpacity` → `withValues(alpha:)`

**Sesi 2:**
- Bottom nav dikembalikan ke custom `_HealthyBottomNav` asli (`AnimatedContainer` + `Row`), bukan Material 3
- Snackbar: `"Coming Soon"` → `"Segera Hadir"`
- 4 menu: **Beranda**, **Peta**, **Favorit**, **Profil**

### `lib/screens/maps/maps_screen.dart`

**Sesi 1 & 2:**
- `withOpacity` → `withValues(alpha:)` di semua box shadow
- `__` → `_` fix pada unused parameter

### `lib/models/place.dart` (Sesi 2)

- Tambah field `foto` (`String?`) pada konstruktor dan factory `fromJson`
- Tambah getter `String? get effectiveFotoUrl => foto` untuk akses konsisten

### `lib/services/api_service.dart` (Sesi 2)

- Base URL diubah ke: `https://campus-healt-api-production.up.railway.app`

### `lib/widgets/facility_card.dart` (Sesi 2)

- Diubah dari `StatefulWidget` → `StatelessWidget` (setelah hapus favorites listener)
- Tambah foto carousel horizontal via `Image.network` + `place.effectiveFotoUrl`
- Fallback ke icon `local_hospital` jika foto `null` / gagal load
- Hapus semua kode terkait Favorit (icon bookmark, listener, dll)

### `lib/widgets/place_card.dart` (Sesi 2)

- Diubah dari `StatefulWidget` → `StatelessWidget`
- Tambah foto via `Image.network` di sebelah kiri
- Fallback ke icon `local_hospital` jika foto `null` / gagal load
- Hapus semua kode terkait Favorit

### `test/widget_test.dart`

- `CampusHealthApp()` → `HealthyUnairApp()`

### `pubspec.yaml`

- Tambah dependency: `flutter_tts: ^4.2.2`

### `pubspec.lock`

- Entry `flutter_tts` version 4.2.5

### Platform Generated Files

- `macos/Flutter/GeneratedPluginRegistrant.swift` — registrasi `FlutterTtsPlugin`
- `windows/flutter/generated_plugin_registrant.cc` — registrasi `FlutterTtsPlugin`
- `windows/flutter/generated_plugins.cmake` — tambah `flutter_tts`

---

## Dependency Baru

- `flutter_tts: ^4.2.2` — Text-to-Speech untuk voice navigation
