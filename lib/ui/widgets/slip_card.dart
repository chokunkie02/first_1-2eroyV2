import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/slip_scanner_service.dart';
import '../../data/category_knowledge.dart'; // Assuming this exists or we use a simple list

class SlipCardWidget extends StatefulWidget {
  final File imageFile;
  final SlipData initialData;
  final VoidCallback onDelete;
  final Function(SlipData updatedData, String category) onSave;
  final bool isSaved;

  const SlipCardWidget({
    super.key,
    required this.imageFile,
    required this.initialData,
    required this.onDelete,
    required this.onSave,
    this.isSaved = false,
  });

  @override
  State<SlipCardWidget> createState() => _SlipCardWidgetState();
}

class _SlipCardWidgetState extends State<SlipCardWidget> {
  late TextEditingController _bankController;
  late TextEditingController _amountController;
  late TextEditingController _memoController;
  late DateTime _date;
  String _selectedCategory = 'Uncategorized';
  
  // Simple category list for now, can be expanded
  final List<String> _categories = [
    'Uncategorized',
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Transfer',
    'Entertainment',
    'Health',
  ];

  @override
  void initState() {
    super.initState();
    _bankController = TextEditingController(text: widget.initialData.bank);
    _amountController = TextEditingController(text: widget.initialData.amount.toStringAsFixed(2));
    _memoController = TextEditingController(text: widget.initialData.memo ?? '');
    _date = widget.initialData.date;
  }

  @override
  void dispose() {
    _bankController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Distinct Visual Style: Amber/Gold background
    final backgroundColor = widget.isSaved ? Colors.green.shade100 : Colors.amber.shade100;

    return Card(
      color: backgroundColor,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Image Thumbnail + Date + Delete
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    widget.imageFile,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Picker Trigger
                      InkWell(
                        onTap: widget.isSaved ? null : _pickDate,
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              "${_date.day}/${_date.month}/${_date.year}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Bank Name Field
                      TextField(
                        controller: _bankController,
                        enabled: !widget.isSaved,
                        decoration: const InputDecoration(
                          labelText: 'Bank / Title',
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                if (!widget.isSaved)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
            const Divider(color: Colors.black26),
            
            // Body: Amount, Category, Memo
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountController,
                    enabled: !widget.isSaved,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '฿ ',
                      border: OutlineInputBorder(),
                      fillColor: Colors.white54,
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      fillColor: Colors.white54,
                      filled: true,
                    ),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: widget.isSaved ? null : (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              enabled: !widget.isSaved,
              decoration: const InputDecoration(
                labelText: 'Memo / Note',
                border: OutlineInputBorder(),
                fillColor: Colors.white54,
                filled: true,
              ),
            ),

            // Footer: Save Button
            if (!widget.isSaved) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final updatedSlip = SlipData(
                      bank: _bankController.text,
                      amount: double.tryParse(_amountController.text) ?? 0.0,
                      date: _date,
                      memo: _memoController.text,
                    );
                    widget.onSave(updatedSlip, _selectedCategory);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Save Transaction"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }
}
