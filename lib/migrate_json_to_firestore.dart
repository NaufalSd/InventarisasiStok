import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await migrateJsonToFirestore();
  print("Migrasi selesai!");
  // Tutup aplikasi jika dijalankan sebagai standalone script
}

// Fungsi migrasi JSON ke Firestore
Future<void> migrateJsonToFirestore() async {
  // 1️⃣ Load JSON dari assets
  final String jsonString = await rootBundle.loadString('assets/data.json');
  final List<dynamic> data = json.decode(jsonString);

  final CollectionReference productsCollection = FirebaseFirestore.instance
      .collection('produk');

  // 2️⃣ Iterasi setiap produk dan simpan ke Firestore
  for (var item in data) {
    try {
      await productsCollection.add({
        "name": item['name'] ?? '-',
        "category": item['category'] ?? '-',
        "price": item['price'] ?? 0,
        "stock": item['stock'] ?? 0,
        "stockMinimum": item['stockMinimum'] ?? 0,
        "imagePath": item['imagePath'] ?? '',
        "timestamp": item['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      });
      print("Berhasil menambahkan: ${item['name']}");
    } catch (e) {
      print("Gagal menambahkan ${item['name']}: $e");
    }
  }
}
