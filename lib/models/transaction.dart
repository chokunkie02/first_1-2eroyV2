import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  late String item;

  @HiveField(1)
  late double price;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  late String? category;

  @HiveField(4)
  double? qty;

  @HiveField(5)
  String? note;

  @HiveField(6)
  String? slipImagePath;

  @HiveField(7)
  String? type; // 'expense' or 'income'

  Transaction({
    required this.item,
    required this.price,
    required this.date,
    this.category = 'Uncategorized',
    this.qty = 1.0,
    this.note,
    this.slipImagePath,
    this.type = 'expense', // Default to expense
  });
}
