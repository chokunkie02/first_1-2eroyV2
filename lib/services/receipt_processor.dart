import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart'; // For compute
import 'package:flutter/widgets.dart';
import '../core/constants.dart';
import 'ai_service.dart';

class ReceiptProcessor {
  final AIService _aiService;

  ReceiptProcessor(this._aiService);

  /// Helper to get raw string from AI stream
  Future<String> _getAIResponse(String input, String promptTemplate) async {
    String fullResponse = "";
    // เรียกใช้ AI ด้วย Prompt ที่ส่งมา (หรือ Default)
    await for (final part in _aiService.processStep(input, promptTemplate)) {
      fullResponse += part;
    }
    print("[AI_DEBUG] Raw Response: [$fullResponse]");
    return fullResponse;
  }

  /// Main logic: รับข้อความ -> ส่ง AI -> แปลง JSON -> คำนวณราคา
  Future<List<Map<String, dynamic>>> processInputSteps(String rawInput, {String? promptTemplate}) async {
    // Use provided template or default to Expense Prompt
    final String effectivePrompt = promptTemplate ?? AppConstants.kExpenseSystemPrompt;

    try {
      // 1. ส่งข้อความทั้งหมดให้ AI ประมวลผลทีเดียว
      String aiResponse = await _getAIResponse(rawInput, effectivePrompt);

      // 2. Offload parsing to background isolate
      return await compute(_parseAIResponse, aiResponse);

    } catch (e) {
      print("ReceiptProcessor Error: $e");
      return [];
    }
  }
}

// Top-level function for compute
List<Map<String, dynamic>> _parseAIResponse(String aiResponse) {
  List<Map<String, dynamic>> results = [];
  
  try {
    // 1. ล้าง Markdown (ถ้ามี)
    String cleanText = aiResponse.replaceAll('```json', '').replaceAll('```', '').trim();

    // 2. แยกบรรทัด (1 บรรทัด = 1 รายการ)
    List<String> lines = cleanText.split('\n');

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      try {
        // หาขอบเขตของ JSON {...}
        int start = line.indexOf('{');
        int end = line.lastIndexOf('}');
        
        if (start != -1 && end != -1) {
          String jsonStr = line.substring(start, end + 1);
          
          // แปลง String เป็น Object
          Map<String, dynamic> data = jsonDecode(jsonStr);

          // Check for Income Format (amount only)
          if (data.containsKey('amount') && !data.containsKey('item')) {
             double amount = double.tryParse(data['amount']?.toString() ?? "0") ?? 0.0;
             String source = data['source']?.toString() ?? "ไม่ระบุ";
             
             // print("[AI_DEBUG] Parsed Income: $amount | Source: $source"); // print might not work
             results.add({
               'amount': amount,
               'source': source,
               'type': 'income',
             });
          } else {
            // Expense Format
            // ดึงข้อมูล (พร้อมค่า Default กันพัง)
            String name = data['item']?.toString() ?? "ไม่ระบุ";
            double qty = double.tryParse(data['qty']?.toString() ?? "1") ?? 1.0;
            
            // เช็ค key ราคา (รองรับทั้ง unit_price และ price เผื่อ AI สับสน)
            double unitPrice = 0.0;
            if (data.containsKey('unit_price')) {
               unitPrice = double.tryParse(data['unit_price']?.toString() ?? "0") ?? 0.0;
            } else if (data.containsKey('price')) {
               unitPrice = double.tryParse(data['price']?.toString() ?? "0") ?? 0.0;
            }

            // คำนวณราคารวม (System Calculation)
            double totalPrice = qty * unitPrice;

            // ดึงหมวดหมู่ (โมเดลใหม่ควรตอบกลับมาเลย)
            String category = data['category']?.toString() ?? "อื่นๆ";

            // print("[AI_DEBUG] Parsed Expense: $name | Qty: $qty | Unit: $unitPrice | Cat: $category");

            results.add({
              'item': name,
              'qty': qty,
              'unit_price': unitPrice,
              'price': totalPrice,
              'category': category,
              'type': 'expense',
            });
          }
        }
      } catch (e) {
        print("[AI_DEBUG] Error parsing line: $line -> $e");
      }
    }
  } catch (e) {
    print("[AI_DEBUG] Error in parsing isolate: $e");
  }

  return results;
}