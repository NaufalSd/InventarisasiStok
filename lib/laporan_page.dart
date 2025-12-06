import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({Key? key}) : super(key: key);

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // === Ambil data dari Firestore ===
  Future<void> _loadProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('produk')
          .get();

      final List<Map<String, dynamic>> loaded = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          _products = loaded;
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat data Firestore: $e');
      if (mounted) {
        setState(() => _products = []);
      }
    }
  }

  // === DIAGRAM BATANG PERGERAKAN STOK ===
  List<BarChartGroupData> _generateBarChart() {
    return List.generate(_products.length, (index) {
      final double stock = ((_products[index]['stock'] ?? 0) as num).toDouble();
      final double minStock = ((_products[index]['stokMinimum'] ?? 0) as num)
          .toDouble();

      final barColor = stock < minStock ? Colors.red : Colors.blue;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: stock,
            width: 16,
            color: barColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  // === CARD RINGKASAN ===
  Widget _buildStockSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    required Color iconBgColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // === DISTRIBUSI KATEGORI ===
  Widget _buildCategoryDistributionItem(
    String name,
    int count,
    Color color,
    double percentage,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(name, style: const TextStyle(fontSize: 15)),
          ),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // === ITEM RIWAYAT ===
  Widget _buildProductAdditionItem(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data['color'],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      data['date'].split(" ").first,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.circle, size: 4, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      data['details'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.circle, size: 4, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      data['type'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data['source'],
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data['qty'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: data['color'],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data['price'],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalStock = _products
        .fold<num>(0, (sum, p) => sum + (p['stock'] ?? 0))
        .toInt();

    int lowStock = _products
        .where(
          (p) =>
              ((p['stock'] ?? 0) as num).toInt() <=
              ((p['stokMinimum'] ?? 0) as num).toInt(),
        )
        .length;

    int outOfStock = _products
        .where((p) => ((p['stock'] ?? 0) as num).toInt() == 0)
        .length;

    int categoryCount = _products.map((p) => p['category']).toSet().length;

    // Distribusi kategori
    final categories = _products.map((p) => p['category']).toSet();
    List<Map<String, dynamic>> categoryDistribution = [];
    int colorIndex = 0;

    for (var cat in categories) {
      final items = _products.where((p) => p['category'] == cat).toList();
      categoryDistribution.add({
        'name': cat,
        'count': items.length,
        'percentage':
            items.length / (_products.isNotEmpty ? _products.length : 1),
        'color': Colors.primaries[colorIndex % Colors.primaries.length],
      });
      colorIndex++;
    }

    // Riwayat
    List<Map<String, dynamic>> history = _products.reversed.map((p) {
      return {
        'name': p['name'] ?? 'Tanpa Nama',
        'details': 'Kategori: ${p['category']}',
        'date': DateTime.now().toString().split('.')[0],
        'source': 'Firebase Firestore',
        'type': 'Produk Baru',
        'qty': '+${p['stock']} pcs',
        'price': 'Rp ${p['price']}',
        'color': Colors.green,
      };
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Laporan Stok",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: _products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === Card Ringkasan ===
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.35,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildStockSummaryCard(
                        icon: Icons.shopping_cart_outlined,
                        iconColor: Colors.blue,
                        title: "Total Stok",
                        value: "$totalStock",
                        unit: "pcs",
                        iconBgColor: Colors.blue.shade50,
                      ),
                      _buildStockSummaryCard(
                        icon: Icons.error_outline,
                        iconColor: Colors.red,
                        title: "Stok Rendah",
                        value: "$lowStock",
                        unit: "items",
                        iconBgColor: Colors.red.shade50,
                      ),
                      _buildStockSummaryCard(
                        icon: Icons.cancel_outlined,
                        iconColor: Colors.redAccent,
                        title: "Stok Habis",
                        value: "$outOfStock",
                        unit: "items",
                        iconBgColor: Colors.red.shade100,
                      ),
                      _buildStockSummaryCard(
                        icon: Icons.category_outlined,
                        iconColor: Colors.purple,
                        title: "Kategori",
                        value: "$categoryCount",
                        unit: "jenis",
                        iconBgColor: Colors.purple.shade50,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // === Distribusi kategori ===
                  const Text(
                    "Distribusi Kategori",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Column(
                    children: categoryDistribution
                        .map(
                          (item) => _buildCategoryDistributionItem(
                            item['name'],
                            item['count'],
                            item['color'],
                            item['percentage'],
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 20),

                  // === DIAGRAM BATANG PERGERAKAN STOK ===
                  const Text(
                    "Pergerakan Stok",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    height: 260,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: BarChart(
                      BarChartData(
                        barGroups: _generateBarChart(),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < _products.length) {
                                  return Text(
                                    _products[value.toInt()]['name']
                                        .toString()
                                        .substring(0, 1),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // === Riwayat ===
                  const Text(
                    "Riwayat Penambahan Produk",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    itemBuilder: (context, index) =>
                        _buildProductAdditionItem(history[index]),
                  ),
                ],
              ),
            ),
    );
  }
}
