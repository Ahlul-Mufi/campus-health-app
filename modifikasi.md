# Modifikasi Hari Ini — 14 Juni 2026

## Ringkasan

Rebranding aplikasi dari **Campus Health** → **Healthy UNAIR**. Penambahan sistem navigasi (bottom nav, maps screen, turn-by-turn navigation dengan TTS), perombakan home screen, dan perubahan warna ke tema hijau.

---

## File Baru

| File                                | Keterangan                                                                                                                                 |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `lib/screens/main_shell.dart`       | Bottom navigation shell (Home, Map, Favorites, Profile) dengan `IndexedStack`. Favorites & Profile menampilkan snackbar "Coming Soon".     |
| `lib/screens/maps/maps_screen.dart` | Halaman peta interaktif dengan `flutter_map`, marker tempat kesehatan, filter kategori, lokasi user real-time, bottom sheet detail tempat. |

## File Dimodifikasi

### `lib/main.dart`

- `CampusHealthApp` → `HealthyUnairApp`
- Tema diubah ke warna hijau (`#0D631B`) dengan `ColorScheme` lengkap
- Home → `MainShell`

### `lib/screens/home/home_screen.dart`

- **Redesain total** dari layout kolom sederhana menjadi `CustomScrollView` + `SliverAppBar`
- Search bar dengan ikon + clear button
- Categories row (FutureBuilder, 3 chip: Rumah Sakit, Klinik, Puskesmas)
- Nearby Facilities horizontal scroll (FutureBuilder, card dengan image placeholder + rating)
- Recommended for You vertical list dengan info lengkap (address, rating, jam buka)
- Skeleton loading untuk semua state loading
- Tap category → `ListScreen`, tap place → `DetailScreen`
- Warna diubah: `withOpacity` → `withValues(alpha:)` untuk kompatibilitas

### `lib/screens/detail/detail_screen.dart`

- **Mode navigasi turn-by-turn**: tombol "Mulai Rute", navigation card dengan instruksi langkah, progress bar, ETA, tombol berhenti
- `FlutterTts` untuk voice instruction (import & instance)
- `_scale` factor untuk responsive UI
- Tombol "Mulai Rute" di info section dan route info card
- Route info card didesain ulang: layout wrap, tombol mulai rute, close button
- Warna diubah: `#96B6C5` → `#0D631B`, `#222222` → `#1B1C17`, dll.
- `_buildNavigationCard()` — widget baru untuk tampilan navigasi aktif
- `_stepIcon()`, `_showAllSteps()`, `_openNavigation()` — method baru
- `padding` dan `fontSize` menggunakan `_scale`

### `lib/screens/list/list_screen.dart`

- Background: `#F1F0E8` → `#FBF9F1`
- AppBar: gradient `#96B6C5`/`#ADC4CE` → solid `#0D631B`
- Warna teks dan icon disesuaikan ke tema hijau

### `lib/screens/main_shell.dart`

- Bottom nav tap handler: jika index >= jumlah screen, tampilkan snackbar "Coming Soon"
- `withOpacity` → `withValues(alpha:)`

### `lib/screens/maps/maps_screen.dart`

- `withOpacity` → `withValues(alpha:)` di semua box shadow
- `onTap` parameter `__` → `_` (minor fix)

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
