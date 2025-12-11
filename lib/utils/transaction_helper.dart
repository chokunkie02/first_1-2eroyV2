import '../models/chat_message.dart';
import '../services/database_service.dart';
import '../services/category_classifier_service.dart';

class TransactionHelper {
  static Future<void> saveSlipAsTransaction(ChatMessage message, Map<String, dynamic> slipData) async {
    if (message.isSaved) return;

    // 1. Robust Fallback for Category
    String category = slipData['category'] ?? 'Uncategorized';
    if (category == 'Uncategorized' || category == null) {
       // Try to auto-classify again (in case UI didn't run it yet)
       String contextText = "${slipData['bank']} ${slipData['recipient']} ${slipData['memo']}";
       category = CategoryClassifierService().suggestCategory(contextText);
       slipData['category'] = category; // Update the map
    }

    // 2. Robust Fallback for Memo (Item Name)
    String itemName = slipData['memo'] ?? '';
    if (itemName.isEmpty) {
      itemName = slipData['recipient'] ?? 'Unspecified Expense';
      slipData['memo'] = itemName; // Update the map
    }

    await DatabaseService().addTransaction(
      itemName,
      (slipData['amount'] ?? 0.0).toDouble(),
      category: category,
      date: slipData['date'] is DateTime ? slipData['date'] : DateTime.now(),
      note: slipData['bank'],
      slipImagePath: message.imagePath,
      type: 'expense', // Slips are expenses for now
    );
    
    // Ensure message object is updated before saving
    message.slipData = slipData;
    message.isSaved = true;
    await message.save();
  }
}
