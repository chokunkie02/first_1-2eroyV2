import 'package:flutter/material.dart';

class CategoryStyles {
  static IconData getIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('food') || cat.contains('อาหาร')) return Icons.restaurant;
    if (cat.contains('transport') || cat.contains('เดินทาง')) return Icons.directions_bus;
    if (cat.contains('shopping') || cat.contains('ช้อปปิ้ง') || cat.contains('ของใช้')) return Icons.shopping_bag;
    if (cat.contains('bill') || cat.contains('บิล')) return Icons.receipt_long;
    if (cat.contains('transfer') || cat.contains('โอน')) return Icons.swap_horiz;
    if (cat.contains('entertainment') || cat.contains('บันเทิง')) return Icons.movie;
    if (cat.contains('health') || cat.contains('สุขภาพ')) return Icons.medical_services;
    if (cat.contains('salary') || cat.contains('เงินเดือน')) return Icons.attach_money;
    return Icons.category;
  }

  static Color getColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('food') || cat.contains('อาหาร')) return Colors.orange;
    if (cat.contains('transport') || cat.contains('เดินทาง')) return Colors.blue;
    if (cat.contains('shopping') || cat.contains('ช้อปปิ้ง') || cat.contains('ของใช้')) return Colors.purple;
    if (cat.contains('bill') || cat.contains('บิล')) return Colors.red;
    if (cat.contains('transfer') || cat.contains('โอน')) return Colors.teal;
    if (cat.contains('entertainment') || cat.contains('บันเทิง')) return Colors.pink;
    if (cat.contains('health') || cat.contains('สุขภาพ')) return Colors.green;
    if (cat.contains('salary') || cat.contains('เงินเดือน')) return Colors.amber;
    return Colors.grey;
  }
  static String getThaiName(String category) {
    const map = {
      'Food': 'อาหาร',
      'Transport': 'เดินทาง',
      'Shopping': 'ช้อปปิ้ง',
      'Health': 'สุขภาพ',
      'Entertainment': 'บันเทิง',
      'Bills': 'บิล',
      'Salary': 'เงินเดือน',
      'Other': 'อื่นๆ',
      'Transfer': 'โอนเงิน',
      'Uncategorized': 'ไม่ระบุ',
    };
    return map[category] ?? category;
  }
}
