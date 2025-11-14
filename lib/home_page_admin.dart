import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'katalog_page.dart';
import 'laporan_page.dart';
import 'login_page.dart';

class HomePageAdmin extends StatefulWidget {
  const HomePageAdmin({Key? key}) : super(key: key);

  @override
  State<HomePageAdmin> createState() => _HomePageAdminState();
}

class _HomePageAdminState extends State<HomePageAdmin> {
  int _selectedIndex = 0;

  late final Stream<QuerySnapshot> productsStream;

  @override
  void initState() {
    super.initState();
    productsStream = FirebaseFirestore.instance
        .collection('produk')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil Logout.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal Logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSummaryCard({
    required Widget iconWidget,
    required String title,
    required String value,
    required Color color,
    required Color backgroundColor,
    required String unit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconWidget,
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final stock = (product['stock'] as int);
    final minStock = (product['minStock'] as int);
    final status = stock <= minStock ? 'Stok Rendah' : 'Stok Aman';
    final statusColor = status == 'Stok Rendah' ? Colors.orange : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.cancel_presentation_sharp,
            color: Colors.black54,
          ),
        ),
        title: Text(
          product['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategori: ${product['category'] ?? '-'}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Text(
              'Stok: ${product['stock'] ?? 0} (Min: ${product['minStock'] ?? 0})',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rp ${product['price'] ?? 0}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    // Trigger StreamBuilder refresh by rebuilding widget
    setState(() {});
  }

  Widget _buildHomeContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Terjadi error koneksi: ${snapshot.error}'),
          );
        }

        final products = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['stock'] = (data['stock'] is num)
              ? (data['stock'] as num).toInt()
              : 0;
          data['minStock'] = (data['minStock'] is num)
              ? (data['minStock'] as num).toInt()
              : 0;
          return data;
        }).toList();

        final totalBarang = products.length;
        final stokRendah = products
            .where((p) => p['stock'] <= p['minStock'])
            .length;
        final stokAman = totalBarang - stokRendah;
        final kategori = products
            .map((p) => p['category'] ?? '-')
            .toSet()
            .length;
        final latestProducts = products.take(5).toList();

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'StokBaju',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pantau stok dan laporan barang dengan mudah',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Ringkasan Stok',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.15,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    children: [
                      _buildSummaryCard(
                        iconWidget: const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.blue,
                        ),
                        title: 'Total Barang',
                        value: totalBarang.toString(),
                        color: Colors.blue,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        unit: 'items',
                      ),
                      _buildSummaryCard(
                        iconWidget: const Icon(
                          Icons.warning_amber,
                          color: Colors.orange,
                        ),
                        title: 'Stok Rendah',
                        value: stokRendah.toString(),
                        color: Colors.orange,
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        unit: 'items',
                      ),
                      _buildSummaryCard(
                        iconWidget: const Icon(
                          Icons.category,
                          color: Colors.purple,
                        ),
                        title: 'Kategori',
                        value: kategori.toString(),
                        color: Colors.purple,
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        unit: 'jenis',
                      ),
                      _buildSummaryCard(
                        iconWidget: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        title: 'Stok Aman',
                        value: stokAman.toString(),
                        color: Colors.green,
                        backgroundColor: Colors.green.withOpacity(0.1),
                        unit: 'items',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Stok Barang Terbaru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: latestProducts.length,
                    itemBuilder: (context, index) =>
                        _buildProductCard(latestProducts[index]),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget _getPage(int index) {
      switch (index) {
        case 0:
          return _buildHomeContent();
        case 1:
          return const KatalogPage();
        case 2:
          return const LaporanPage();
        default:
          return _buildHomeContent();
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 0 ? Icons.home : Icons.home_outlined),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 1 ? Icons.book : Icons.book_outlined),
            label: 'Katalog',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 2 ? Icons.bar_chart : Icons.bar_chart_outlined,
            ),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}
