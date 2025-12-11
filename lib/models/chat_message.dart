import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 1)
class ChatMessage extends HiveObject {
  @HiveField(0)
  late String text;

  @HiveField(1)
  late bool isUser;

  @HiveField(2)
  late DateTime timestamp;

  @HiveField(3)
  late List<Map<dynamic, dynamic>>? expenseData; // Store extracted data for AI cards

  @HiveField(4)
  late bool isSaved; // To track if the user has already saved this card

  @HiveField(5)
  late String? imagePath;

  @HiveField(6)
  late Map<dynamic, dynamic>? slipData; // Store OCR results

  @HiveField(7)
  late String? mode; // 'expense' or 'income'

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.expenseData,
    this.isSaved = false,
    this.imagePath,
    this.slipData,
    this.mode,
  });
}
