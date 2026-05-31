import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/api_service.dart';
import '../../widgets/category_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../list/list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  late Future<List<Category>> _categories;

  @override
  void initState() {
    super.initState();
    _categories = _api.getCategories();
  }

  IconData _iconForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'rumah sakit':
        return Icons.local_hospital;
      case 'klinik':
        return Icons.medical_services;
      case 'puskesmas':
        return Icons.health_and_safety;
      default:
        return Icons.place;
    }
  }

  Color _colorForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'rumah sakit':
        return const Color(0xFF96B6C5);
      case 'klinik':
        return const Color(0xFFADC4CE);
      case 'puskesmas':
        return const Color(0xFFEEE0C9);
      default:
        return const Color(0xFFADC4CE);
    }
  }

  void _pushList(Category cat) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => ListScreen(category: cat),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF96B6C5), Color(0xFFADC4CE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: const Text(
              'Campus Health',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Cari Fasilitas Kesehatan',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Temukan rumah sakit, klinik, dan puskesmas di sekitar kampus',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: FutureBuilder<List<Category>>(
                future: _categories,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: 4,
                      itemBuilder: (ctx, i) => const ShimmerLoading(
                        height: double.infinity,
                        borderRadius: 16,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off,
                              size: 48, color: Color(0xFFADC4CE)),
                          const SizedBox(height: 16),
                          Text(
                            'Gagal memuat data',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final categories = snapshot.data!;
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return CategoryCard(
                        title: cat.name,
                        icon: _iconForCategory(cat.name),
                        color: _colorForCategory(cat.name),
                        onTap: () => _pushList(cat),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
