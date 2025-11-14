import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'katalog_page.dart';
import 'tambah_page.dart';
import 'laporan_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final GlobalKey<KatalogPageState> _katalogKey = GlobalKey<KatalogPageState>();
  late KatalogPage _katalogPage;

  List<Map<String, dynamic>> _latestProducts = [];

  @override
  void initState() {
    super.initState();
    _katalogPage = KatalogPage(key: _katalogKey);
    _loadProducts(); // ambil data dari Firestore
  }

  // ======== Ambil data dari Firestore ========
  Future<void> _loadProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('produk')
          .get();

      final List<Map<String, dynamic>> products = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (mounted) setState(() => _latestProducts = products);
    } catch (e) {
      debugPrint('Gagal memuat data dari Firestore: $e');
      if (mounted) setState(() => _latestProducts = []);
    }
  }

  // ======== Callback ketika produk diubah dari TambahPage ========
  Future<void> _onProductUpdated() async {
    await _loadProducts();
    try {
      _katalogKey.currentState?.refreshProducts();
    } catch (_) {}
    if (mounted) setState(() => _selectedIndex = 0);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal Logout: $e')));
    }
  }

  // ================== UI Builder ==================
  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    required Color cardColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    int stock = (product['stock'] is int)
        ? product['stock'] as int
        : int.tryParse('${product['stock']}') ?? 0;
    int minStock = (product['stokMinimum'] is int)
        ? product['stokMinimum'] as int
        : int.tryParse('${product['stokMinimum']}') ?? 0;

    String status = 'Stok Aman';
    Color statusColor = Colors.green;
    if (stock == 0) {
      status = 'Stok Habis';
      statusColor = Colors.red;
    } else if (stock <= minStock) {
      status = 'Stok Rendah';
      statusColor = Colors.orange;
    }

    final imagePath =
        product['imagePath'] ??
        'https://cdn-icons-png.flaticon.com/512/679/679720.png'; // placeholder
    final priceStr = product['price']?.toString() ?? '-';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported),
            ),
          ),
        ),
        title: Text(
          product['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Kategori: ${product['category'] ?? '-'}\nStok: $stock (Min: $minStock)',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Rp $priceStr',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWidgetOptions() {
    return <Widget>[
      _buildHomeContent(),
      _katalogPage,
      TambahPage(onProductAdded: _onProductUpdated),
      const LaporanPage(),
    ];
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: RefreshIndicator(
              onRefresh: _loadProducts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'StokBaju',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pantau stok dan laporan barang dengan mudah',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Ringkasan Stok',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.3,
                      children: [
                        _buildSummaryCard(
                          icon: Icons.inventory,
                          iconColor: Colors.blue,
                          title: 'Total Barang',
                          value: _latestProducts.length.toString(),
                          unit: 'items',
                          cardColor: Colors.blue[50]!,
                        ),
                        _buildSummaryCard(
                          icon: Icons.warning_amber_rounded,
                          iconColor: Colors.orange,
                          title: 'Stok Rendah',
                          value: _latestProducts
                              .where((p) {
                                final stock = (p['stock'] is int)
                                    ? p['stock'] as int
                                    : int.tryParse('${p['stock']}') ?? 0;
                                final min = (p['stokMinimum'] is int)
                                    ? p['stokMinimum'] as int
                                    : int.tryParse('${p['stokMinimum']}') ?? 0;
                                return stock <= min;
                              })
                              .length
                              .toString(),
                          unit: 'items',
                          cardColor: Colors.orange[50]!,
                        ),
                        _buildSummaryCard(
                          icon: Icons.category_outlined,
                          iconColor: Colors.purple,
                          title: 'Kategori',
                          value: _latestProducts
                              .map((p) => p['category'])
                              .toSet()
                              .length
                              .toString(),
                          unit: 'jenis',
                          cardColor: Colors.purple[50]!,
                        ),
                        _buildSummaryCard(
                          icon: Icons.check_circle_outline,
                          iconColor: Colors.green,
                          title: 'Stok Aman',
                          value: _latestProducts
                              .where((p) {
                                final stock = (p['stock'] is int)
                                    ? p['stock'] as int
                                    : int.tryParse('${p['stock']}') ?? 0;
                                final min = (p['stokMinimum'] is int)
                                    ? p['stokMinimum'] as int
                                    : int.tryParse('${p['stokMinimum']}') ?? 0;
                                return stock > min;
                              })
                              .length
                              .toString(),
                          unit: 'items',
                          cardColor: Colors.green[50]!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Stok Barang Terbaru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _latestProducts.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('Belum ada produk ditambahkan.'),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _latestProducts.length,
                            itemBuilder: (context, i) =>
                                _buildProductCard(_latestProducts[i]),
                          ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final widgetOptions = _buildWidgetOptions();
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          const Icon(Icons.notifications_none, color: Colors.blueGrey),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _logout,
            child: const Icon(Icons.person_outline, color: Colors.blueGrey),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: widgetOptions[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.blueGrey,
        backgroundColor: Colors.white,
        elevation: 12,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'Katalog',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add, size: 36), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}
