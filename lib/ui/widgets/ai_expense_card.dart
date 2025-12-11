import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../utils/category_styles.dart';
import 'package:intl/intl.dart';

class AIExpenseCardWidget extends StatefulWidget {
  final ChatMessage message;
  final Function(ChatMessage) onSave;
  final Function(ChatMessage)? onDelete; // New callback

  const AIExpenseCardWidget({
    super.key,
    required this.message,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<AIExpenseCardWidget> createState() => _AIExpenseCardWidgetState();
}

class _AIExpenseCardWidgetState extends State<AIExpenseCardWidget> {
  late List<Map<dynamic, dynamic>> _items;
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
    _items = List<Map<dynamic, dynamic>>.from(
      (widget.message.expenseData ?? []).map((e) => Map<dynamic, dynamic>.from(e))
    );
  }

  void _updateItem(int index, String key, dynamic value) {
    setState(() {
      _items[index][key] = value;
    });
    widget.message.expenseData = _items;
    widget.message.save();
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยกเลิกรายการ?"),
        content: const Text("คุณต้องการลบรายการนี้ใช่หรือไม่?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ไม่"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("ใช่, ลบเลย"),
          ),
        ],
      ),
    );

    if (confirm == true && widget.onDelete != null) {
      widget.onDelete!(widget.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaved = widget.message.isSaved;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: isSaved ? null : Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Text(
                    "รายการที่ AI แนะนำ",
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.amber[800]
                    ),
                  ),
                ],
              ),
              // Date Picker
              InkWell(
                onTap: isSaved ? null : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: widget.message.timestamp,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      widget.message.timestamp = picked;
                      widget.message.save();
                    });
                  }
                },
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "วันที่: ${widget.message.timestamp.day}/${widget.message.timestamp.month}/${widget.message.timestamp.year}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                    ),
                    if (!isSaved)
                      Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey[600]),
                  ],
                ),
              ),
              const Divider(),

              // List of Items
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final category = item['category'] ?? 'Uncategorized';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CategoryStyles.getColor(category).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CategoryStyles.getIcon(category),
                          size: 16,
                          color: CategoryStyles.getColor(category),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Inputs
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Item Name
                            TextFormField(
                              initialValue: item['item'],
                              enabled: !isSaved,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                                border: InputBorder.none,
                                hintText: 'ชื่อรายการ',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              onChanged: (val) => _updateItem(index, 'item', val),
                            ),
                            
                            // Category Dropdown (Small)
                            if (!isSaved)
                              SizedBox(
                                height: 24,
                                child: DropdownButton<String>(
                                  value: _categories.contains(category) ? category : 'Uncategorized',
                                  isDense: true,
                                  underline: Container(),
                                  icon: const Icon(Icons.arrow_drop_down, size: 16),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  items: _categories.map((c) => DropdownMenuItem(
                                    value: c, 
                                    child: Text(CategoryStyles.getThaiName(c)),
                                  )).toList(),
                                  onChanged: (val) {
                                    if (val != null) _updateItem(index, 'category', val);
                                  },
                                ),
                              )
                            else
                              Text(CategoryStyles.getThaiName(category), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      
                      // Quantity
                      SizedBox(
                        width: 40,
                        child: TextFormField(
                          initialValue: (item['qty'] ?? 1).toString(),
                          enabled: !isSaved,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            border: InputBorder.none,
                            prefixText: 'x',
                            prefixStyle: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                          onChanged: (val) => _updateItem(index, 'qty', double.tryParse(val) ?? 1.0),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Price
                      SizedBox(
                        width: 70,
                        child: TextFormField(
                          initialValue: (item['price'] ?? 0).toString(),
                          enabled: !isSaved,
                          textAlign: TextAlign.right,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            border: InputBorder.none,
                            prefixText: '฿',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          onChanged: (val) => _updateItem(index, 'price', double.tryParse(val) ?? 0.0),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const Divider(),

              // Save Button
              if (!isSaved)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onSave(widget.message),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text("ยืนยันและบันทึก"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: const Text("บันทึกแล้ว ✓", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
        
        // Delete Button (Top Right)
        if (!isSaved && widget.onDelete != null)
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _confirmDelete,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.red),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
