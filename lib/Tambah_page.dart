import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TambahPage extends StatefulWidget {
  final VoidCallback onProductAdded;
  const TambahPage({Key? key, required this.onProductAdded}) : super(key: key);

  @override
  _TambahPageState createState() => _TambahPageState();
}

class _TambahPageState extends State<TambahPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stokAwalController = TextEditingController();
  final TextEditingController _stokMinimumController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _editStockController = TextEditingController();

  String? _selectedCategory;
  String? _selectedSize; // 👈 DITAMBAHKAN
  List<Map<String, dynamic>> _products = [];
  String? _selectedProductTambah;
  String? _selectedProductEdit;

  final List<String> _kategoriList = [
    'Shortsleeve Black',
    'Shortsleeve Faded',
    'Longsleeve Black',
    'Longsleeve Faded',
  ];

  final List<String> _sizeList = ['S', 'M', 'L', 'XL', 'XXL']; // 👈 DITAMBAHKAN

  final CollectionReference _produkCollection = FirebaseFirestore.instance
      .collection('produk');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _stokAwalController.dispose();
    _stokMinimumController.dispose();
    _stockController.dispose();
    _editStockController.dispose();
    super.dispose();
  }

  // ===== Ambil Produk dari Firebase =====
  Future<void> _loadProducts() async {
    try {
      final snapshot = await _produkCollection.get();
      setState(() {
        _products = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      });
    } catch (e) {
      debugPrint('Error load products: $e');
    }
  }

  // ===== Tambah Produk Baru =====
  Future<void> _onSaveProduct() async {
    final name = _nameController.text.trim();
    final price = _priceController.text.trim();
    final stokAwal = _stokAwalController.text.trim();
    final stokMinimum = _stokMinimumController.text.trim();
    final category = _selectedCategory ?? '';
    final size = _selectedSize ?? ''; // 👈 DITAMBAHKAN

    if (name.isEmpty ||
        price.isEmpty ||
        category.isEmpty ||
        size.isEmpty || // 👈 WAJIB ISI SIZE
        stokAwal.isEmpty ||
        stokMinimum.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua kolom wajib diisi!')));
      return;
    }

    try {
      final existing = await _produkCollection
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nama produk sudah ada!')));
        return;
      }

      await _produkCollection.add({
        'name': name,
        'category': category,
        'size': size, // 👈 DISIMPAN KE FIREBASE
        'price': price,
        'stock': int.tryParse(stokAwal) ?? 0,
        'stockMinimum': int.tryParse(stokMinimum) ?? 0,
        'imagePath': 'assets/placeholder.png',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      await _loadProducts();
      widget.onProductAdded();

      _nameController.clear();
      _priceController.clear();
      _stokAwalController.clear();
      _stokMinimumController.clear();

      setState(() {
        _selectedCategory = null;
        _selectedSize = null; // 👈 RESET SIZE
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk baru berhasil ditambahkan!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menambahkan produk: $e')));
    }
  }

  // ===== Tambah Stok =====
  Future<void> _addStock() async {
    if (_selectedProductTambah == null || _stockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk dan isi jumlah stok!')),
      );
      return;
    }

    try {
      final productDoc = _produkCollection.doc(_selectedProductTambah);
      final snapshot = await productDoc.get();
      if (!snapshot.exists) return;

      final currentStock = snapshot['stock'] ?? 0;
      final addedStock = int.tryParse(_stockController.text) ?? 0;

      await productDoc.update({'stock': currentStock + addedStock});
      await _loadProducts();
      widget.onProductAdded();

      _stockController.clear();
      setState(() {
        _selectedProductTambah = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok berhasil ditambahkan!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menambah stok: $e')));
    }
  }

  // ===== Edit Stok =====
  Future<void> _editStock() async {
    if (_selectedProductEdit == null || _editStockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk dan isi jumlah keluar!')),
      );
      return;
    }

    try {
      final productDoc = _produkCollection.doc(_selectedProductEdit);
      final snapshot = await productDoc.get();
      if (!snapshot.exists) return;

      final currentStock = snapshot['stock'] ?? 0;
      final removedStock = int.tryParse(_editStockController.text) ?? 0;

      if (removedStock > currentStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jumlah keluar melebihi stok tersedia!'),
          ),
        );
        return;
      }

      await productDoc.update({'stock': currentStock - removedStock});
      await _loadProducts();
      widget.onProductAdded();

      _editStockController.clear();
      setState(() {
        _selectedProductEdit = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok berhasil diperbarui!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengedit stok: $e')));
    }
  }

  // ===== Hapus Produk =====
  Future<void> _deleteProduct() async {
    if (_selectedProductEdit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk yang ingin dihapus!')),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Hapus Produk"),
          content: const Text("Apakah Anda yakin ingin menghapus produk ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _produkCollection.doc(_selectedProductEdit).delete();
      await _loadProducts();
      widget.onProductAdded();

      setState(() => _selectedProductEdit = null);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Produk berhasil dihapus!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menghapus produk: $e")));
    }
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        backgroundColor: Colors.blue,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Produk Baru'),
            Tab(text: 'Tambah Stok'),
            Tab(text: 'Edit Stok'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTambahProduk(), _buildTambahStok(), _buildEditStok()],
      ),
    );
  }

  // ====== UI Produk Baru ======
  Widget _buildTambahProduk() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Produk',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // ===== Dropdown kategori =====
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Kategori',
              border: OutlineInputBorder(),
            ),
            value: _selectedCategory,
            items: _kategoriList
                .map(
                  (kategori) =>
                      DropdownMenuItem(value: kategori, child: Text(kategori)),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),

          const SizedBox(height: 16),

          // ===== Dropdown Size =====
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Size',
              border: OutlineInputBorder(),
            ),
            value: _selectedSize,
            items: _sizeList
                .map((size) => DropdownMenuItem(value: size, child: Text(size)))
                .toList(),
            onChanged: (value) => setState(() => _selectedSize = value),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Harga (Rp)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _stokAwalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Stok Awal',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _stokMinimumController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Stok Minimum',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _onSaveProduct,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.blue,
            ),
            child: const Text('Simpan Produk Baru'),
          ),
        ],
      ),
    );
  }

  // ===== Tambah stok =====
  Widget _buildTambahStok() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Produk',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Pilih produk',
            ),
            value: _selectedProductTambah,
            items: _products
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item['id'].toString(),
                    child: Text(item['name']?.toString() ?? ''),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedProductTambah = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _stockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Jumlah Tambah Stok',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addStock,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Stok'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  // ===== Edit stok =====
  Widget _buildEditStok() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Produk',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Pilih produk untuk edit stok',
            ),
            value: _selectedProductEdit,
            items: _products
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item['id'].toString(),
                    child: Text(item['name']?.toString() ?? ''),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedProductEdit = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _editStockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Jumlah Barang Keluar',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _editStock,
            icon: const Icon(Icons.save),
            label: const Text('Simpan Perubahan'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _deleteProduct,
            icon: const Icon(Icons.delete),
            label: const Text('Hapus Produk'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
