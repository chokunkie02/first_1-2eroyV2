
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
// import '../data/category_knowledge.dart'; // Moved to ReceiptProcessor
import '../core/constants.dart';
import '../services/receipt_processor.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});
// ...
  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final TextEditingController _controller = TextEditingController();
  final AIService _aiService = AIService();
  List<Map<String, dynamic>> _extractedItems = [];
  bool _isLoading = false;
  String _statusMessage = "";

  // _assignCategory moved to ReceiptProcessor

  @override
  void initState() {
    super.initState();
    // Initialize the persistent AI service once
    _aiService.initialize().catchError((e) {
      setState(() => _statusMessage = "Error initializing AI: $e");
    });
  }

  @override
  void dispose() {
    // _aiService.dispose(); // Persistent service, do not dispose
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processInput() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusMessage = "กำลังวิเคราะห์รายการ (AI)...";
      _extractedItems = [];
    });

    try {
      // Use the new robust ReceiptProcessor
      final processor = ReceiptProcessor(_aiService);
      final results = await processor.processInputSteps(_controller.text);

      setState(() {
        _extractedItems = results;
      });

    } catch (e) {
      print("Error in processing: $e");
      _statusMessage = "เกิดข้อผิดพลาด: $e";
    }

    setState(() {
      _isLoading = false;
      if (_extractedItems.isNotEmpty) {
        _statusMessage = "วิเคราะห์ครบแล้ว พบ ${_extractedItems.length} รายการ";
      } else {
        _statusMessage = "ไม่พบรายการที่วิเคราะห์ได้";
      }
    });
  }

  Future<void> _saveItems() async {
    for (var item in _extractedItems) {
      await DatabaseService().addTransaction(
        item['item'], 
        item['price'], 
        category: item['category'],
        qty: item['qty'],
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกเรียบร้อยแล้ว!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('บันทึกรายจ่าย (AI)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'อธิบายรายการใช้จ่าย',
                hintText: 'เช่น ซื้อข้าวกะเพรา 50 บาท และน้ำเปล่า 10 บาท',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _processInput,
              child: _isLoading 
                  ? const CircularProgressIndicator() 
                  : const Text('วิเคราะห์รายการ'),
            ),
            const SizedBox(height: 16),
            Text(_statusMessage, style: const TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _extractedItems.length,
                itemBuilder: (context, index) {
                  final item = _extractedItems[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.shopping_bag),
                      title: Text("${item['item']} (x${(item['qty'] ?? 1.0).toInt()})"),
                      subtitle: Text("หมวดหมู่: ${item['category']} | หน่วยละ: ฿${item['unit_price']}"),
                      trailing: Text("รวม ฿${item['price']}"),
                    ),
                  );
                },
              ),
            ),
            if (_extractedItems.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveItems,
                  icon: const Icon(Icons.save),
                  label: const Text('บันทึกทั้งหมด'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
