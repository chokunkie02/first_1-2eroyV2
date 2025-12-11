import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import 'package:intl/intl.dart';

class AIIncomeCardWidget extends StatefulWidget {
  final ChatMessage message;
  final Function(ChatMessage) onSave;
  final Function(ChatMessage)? onDelete;

  const AIIncomeCardWidget({
    super.key,
    required this.message,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<AIIncomeCardWidget> createState() => _AIIncomeCardWidgetState();
}

class _AIIncomeCardWidgetState extends State<AIIncomeCardWidget> {
  late List<Map<dynamic, dynamic>> _items;

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
            border: isSaved ? null : Border.all(color: Colors.green[200]!),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.05),
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
                  Icon(Icons.monetization_on, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    "รายรับที่ AI พบ",
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.green[800]
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

              // List of Items (Should be 1 usually)
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                
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
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Inputs
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Source Name
                            TextFormField(
                              initialValue: item['source'],
                              enabled: !isSaved,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                                border: InputBorder.none,
                                hintText: 'ที่มา (เช่น เงินเดือน)',
                                labelText: 'ที่มา',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              onChanged: (val) => _updateItem(index, 'source', val),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 8),

                      // Amount
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          initialValue: (item['amount'] ?? 0).toString(),
                          enabled: !isSaved,
                          textAlign: TextAlign.right,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            border: InputBorder.none,
                            prefixText: '+',
                            prefixStyle: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18),
                          onChanged: (val) => _updateItem(index, 'amount', double.tryParse(val) ?? 0.0),
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
                    label: const Text("บันทึกรายรับ"),
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
                    child: Text("บันทึกแล้ว ✓", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
