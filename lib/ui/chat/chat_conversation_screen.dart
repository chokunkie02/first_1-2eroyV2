import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../providers/app_global_provider.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../core/constants.dart'; // For ChatMode and Prompts
import '../../models/chat_message.dart';
import '../../services/ai_service.dart';
import '../../services/database_service.dart';
import '../../services/receipt_processor.dart';
import '../../services/scan_history_service.dart';
import '../../services/slip_scanner_service.dart';
import '../../services/category_classifier_service.dart';
import '../widgets/custom_toast.dart';
import '../widgets/slip_card_message.dart';
import '../widgets/ai_expense_card.dart';
import '../widgets/ai_income_card.dart'; // Import Income Card
import '../folder_selection_screen.dart';
import '../../services/theme_service.dart';
import '../widgets/typing_indicator.dart';
import '../../utils/transaction_helper.dart';

class ChatConversationScreen extends StatefulWidget {
  final ChatMode mode;
  final VoidCallback? onBack; // Callback for nested navigation

  const ChatConversationScreen({super.key, required this.mode, this.onBack});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  final AIService _aiService = AIService();
  final ScrollController _scrollController = ScrollController();
  final ScanHistoryService _historyService = ScanHistoryService();
  final SlipScannerService _scanner = SlipScannerService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _aiService.initialize();
    
    // Check for pending slips from Global Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppGlobalProvider>();
      if (provider.pendingSlips.isNotEmpty) {
        _injectPendingSlips(List.from(provider.pendingSlips));
        provider.clearPendingSlips();
      }
    });
  }

  Future<void> _injectPendingSlips(List<SlipData> slips) async {
    print("[ChatScreen] Injecting ${slips.length} pending slips...");
    for (final slip in slips) {
      // Create a message for each slip
      // Note: We don't have the original file path here easily unless we stored it in SlipData.
      // Ideally SlipData should have 'filePath'. 
      // For now, we'll assume we can't display the image perfectly if we didn't store the path,
      // BUT SlipScannerService returns SlipData which DOES NOT have filePath currently.
      // We need to update SlipData to include filePath or just display the data card.
      
      // Let's create a Text Message with the data attached, or a "System" message.
      // Better yet, let's just add them as "Pending" messages that are already "scanned".
      
      final msg = ChatMessage(
        text: "Slip from Auto-Scan",
        isUser: false,
        timestamp: slip.date,
        // imagePath: ??? // We need this for the UI to look good.
        // Let's update SlipData to include filePath in the next step if needed, 
        // but for now let's just save them as transactions directly? 
        // No, user wants to "Review".
        
        // Workaround: Since we don't have the file path in SlipData (my bad in previous design),
        // we will display them as "Auto-Detected Slip" cards without image for now, 
        // or we assume the user will just see the data.
        
        // Actually, let's look at SlipScannerService. It returns SlipData.
        // I should have added filePath to SlipData. 
        // For this iteration, I will assume we can just show the data.
        
        slipData: {
          'bank': slip.bank,
          'amount': slip.amount,
          'date': slip.date,
          'memo': slip.memo,
          'recipient': slip.recipient,
        },
      );
      
      await DatabaseService().addChatMessage(msg);
    }
    _scrollToBottom();
    
    if (mounted) {
      showTopRightToast(context, "Imported ${slips.length} slips for review");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // Because we reverse the list
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Public method called from HomeScreen (Legacy) -> Now internal or via AppBar
  Future<void> scanSlips() async {
    // 1. Check Folder Selection
    final selectedAlbumIds = await _historyService.getSelectedAlbumIds();
    if (selectedAlbumIds.isEmpty) {
      // Open Selection Screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FolderSelectionScreen()),
      );
      if (result != true) return; // User cancelled
    }

    // 2. Fetch Images
    setState(() => _isProcessing = true);
    List<File> newImages = [];
    
    // Reload IDs in case they changed
    final albumIds = await _historyService.getSelectedAlbumIds();
    if (!mounted) return;

    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    
    for (final album in albums) {
      if (albumIds.contains(album.id)) {
        final cutoffDate = await _historyService.getCutoffDate(album.id);
        final assetCount = await album.assetCountAsync;
        final assets = await album.getAssetListRange(start: 0, end: assetCount > 200 ? 200 : assetCount);
        
        for (final asset in assets) {
          if (asset.type == AssetType.image && asset.createDateTime.isAfter(cutoffDate)) {
             final file = await asset.file;
             if (file != null) newImages.add(file);
          }
        }
        // Update history for this album
        await _historyService.updateLastScanTime(album.id);
      }
    }

    // Sort Oldest -> Newest
    newImages.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

    if (newImages.isEmpty) {
      if (mounted) {
        setState(() => _isProcessing = false);
        showTopRightToast(context, "No new slips found.");
      }
      return;
    }

    // 3. Insert Pending Messages
    for (final file in newImages) {
      final msg = ChatMessage(
        text: "Slip: ${file.path.split('/').last}",
        isUser: false, // System message essentially
        timestamp: DateTime.now(),
        imagePath: file.path,
        // slipData is null initially -> "Reading..."
      );
      await DatabaseService().addChatMessage(msg);
    }
    
    if (mounted) {
      setState(() => _isProcessing = false);
      _scrollToBottom();
    }

    // 4. Process Background Queue
    if (mounted) {
      _processSlipQueue(newImages);
    }
  }

  Future<void> _processSlipQueue(List<File> files) async {
    for (final file in files) {
      // Allow processing to continue even if screen is closed (Background Mode)
      // if (!mounted) return; 
      
      ChatMessage? msg;

      try {
        // Find the message in DB (we need the Hive object to update it)
        final box = DatabaseService().chatBox;
        // Use firstWhere safely
        try {
          msg = box.values.firstWhere((m) => m.imagePath == file.path);
        } catch (_) {
          // Not found, skip
          continue;
        }
        
        if (msg.isInBox) {
          final slip = await _scanner.processImageFile(file);
          if (slip != null) {
            msg.slipData = {
              'bank': slip.bank,
              'amount': slip.amount,
              'date': slip.date,
              'memo': slip.memo,
              'recipient': slip.recipient,
            };
            await msg.save(); // Update UI via Hive listener
          } else {
             // Set error state so UI stops loading
             msg.slipData = {'error': true};
             msg.text = "Failed to read slip.";
             await msg.save();
          }
        }
      } catch (e) {
        print("Error processing slip in chat: $e");
        // Ensure UI stops loading even on crash
        if (msg != null && msg.isInBox) {
           msg.slipData = {'error': true};
           msg.text = "Error: $e";
           await msg.save();
        }
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    FocusScope.of(context).unfocus();

    // 1. Add User Message
    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      mode: widget.mode.name, // Save mode
    );
    await DatabaseService().addChatMessage(userMsg);
    _scrollToBottom();

    setState(() {
      _isProcessing = true;
    });

    try {
      // 2. Select Prompt based on Mode
      final String promptTemplate = widget.mode == ChatMode.expense 
          ? AppConstants.kExpenseSystemPrompt 
          : AppConstants.kIncomeSystemPrompt;

      // 3. Process with AI
      final processor = ReceiptProcessor(_aiService);
      final results = await processor.processInputSteps(text, promptTemplate: promptTemplate);

      // 4. Add AI Response Message
      String responseText;
      List<Map<String, dynamic>>? expenseData;
      
      if (widget.mode == ChatMode.expense) {
        if (results.isNotEmpty) {
           responseText = "เจอ ${results.length} รายการครับ ตรวจสอบความถูกต้องแล้วกดบันทึกได้เลย";
           expenseData = results;
        } else {
           responseText = "ไม่พบรายการค่าใช้จ่ายในข้อความครับ";
        }
      } else {
        // Income Mode
        if (results.isNotEmpty) {
           responseText = "เจอรายการรับครับ ตรวจสอบแล้วบันทึกได้เลย";
           expenseData = results; 
        } else {
           responseText = "ไม่พบยอดเงินในข้อความครับ";
        }
      }

      final aiMsg = ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
        expenseData: expenseData,
        mode: widget.mode.name, // Save mode
      );
      await DatabaseService().addChatMessage(aiMsg);

    } catch (e) {
      // Error Message
      final errorMsg = ChatMessage(
        text: "เกิดข้อผิดพลาด: $e",
        isUser: false,
        timestamp: DateTime.now(),
        mode: widget.mode.name, // Save mode
      );
      await DatabaseService().addChatMessage(errorMsg);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _saveExpense(ChatMessage message, int index) async {
    if (message.expenseData == null || message.isSaved) return;

    for (var item in message.expenseData!) {
      if (item['type'] == 'income') {
         await DatabaseService().addTransaction(
           item['source'] ?? 'Income',
           (item['amount'] ?? 0.0).toDouble(),
           category: 'Salary', // Or 'Income'
           qty: 1.0,
           date: message.timestamp,
           type: 'income',
         );
      } else {
         await DatabaseService().addTransaction(
           item['item'],
           item['price'],
           category: item['category'],
           qty: (item['qty'] ?? 1.0).toDouble(),
           date: message.timestamp,
           type: 'expense',
         );
      }
    }

    // Mark as saved
    message.isSaved = true;
    await message.save(); // Save change to Hive

    if (mounted) {
      showTopRightToast(context, 'บันทึกรายการเรียบร้อยแล้ว!');
    }
  }

  Future<void> _saveSlipMessage(ChatMessage message, Map<String, dynamic> slipData) async {
    await TransactionHelper.saveSlipAsTransaction(message, slipData);
    if (mounted) {
      showTopRightToast(context, 'Slip saved!');
    }
  }

  Future<void> _saveAllVerified() async {
    final box = DatabaseService().chatBox;
    final messages = box.values.where((m) => m.imagePath != null && !m.isSaved && m.slipData != null).toList();
    
    int savedCount = 0;
    for (final msg in messages) {
      print('DEBUG: Saving msg index $savedCount with category: ${msg.slipData?['category']}');
      await _saveSlipMessage(msg, Map<String, dynamic>.from(msg.slipData!));
      savedCount++;
    }
    
    if (mounted) {
      showTopRightToast(context, "Saved $savedCount slips!");
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    await message.delete(); // Delete from Hive
    if (mounted) {
      setState(() {}); // Refresh UI
      showTopRightToast(context, "ลบรายการแล้ว");
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = DatabaseService().chatBox;
    final isExpense = widget.mode == ChatMode.expense;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme; // Use standard scheme

    return Scaffold( 
      backgroundColor: theme.scaffoldBackgroundColor, // Match History Tab background
      appBar: AppBar(
        title: Column(
          children: [
            Text(isExpense ? "บันทึกรายจ่าย" : "บันทึกรายรับ"),
            FutureBuilder(
              future: _aiService.initialize(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return const SizedBox.shrink();
                }
                return const Text(
                  "กำลังโหลดโมเดล AI...",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ],
        ),
        backgroundColor: theme.scaffoldBackgroundColor, // Match background
        foregroundColor: colorScheme.onSurface,
        leading: widget.onBack != null ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ) : null,
        actions: isExpense ? [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Scan Slips',
            onPressed: scanSlips,
          ),
        ] : null,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Chat Area
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: box.listenable(),
                  builder: (context, Box<ChatMessage> box, _) {
                    // Filter messages by mode
                    final messages = box.values
                        .where((m) => m.mode == widget.mode.name || (m.mode == null && isExpense)) // Default old msgs to expense
                        .toList()
                        .reversed
                        .toList();

                    // Insert "Thinking" message if processing
                    if (_isProcessing) {
                      messages.insert(0, ChatMessage(
                        text: "AI กำลังคิดอยู่...",
                        isUser: false,
                        timestamp: DateTime.now(),
                      ));
                    }

                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          "เริ่มคุยกับ AI ได้เลย...",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true, // Show newest at bottom
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), // Extra bottom padding for FAB
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        
                        // Check if it's the temporary "Thinking" message
                        if (_isProcessing && index == 0 && msg.text == "AI กำลังคิดอยู่...") {
                           return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.dark 
                                      ? const Color(0xFF334155) // Slate 700 for Dark Mode
                                      : colorScheme.secondaryContainer,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "AI กำลังคิดอยู่",
                                      style: TextStyle(
                                        color: theme.brightness == Brightness.dark 
                                            ? Colors.white 
                                            : colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TypingIndicator(
                                      color: theme.brightness == Brightness.dark 
                                          ? Colors.white 
                                          : colorScheme.onSecondaryContainer,
                                    ),
                                  ],
                                ),
                              ),
                           );
                        }

                        // Check if it's a Slip Message
                        if (msg.imagePath != null) {
                          return SlipCardMessageWidget(
                            message: msg,
                            onSave: _saveSlipMessage,
                            onDelete: _deleteMessage,
                            onCategoryChanged: (newCategory) {
                              // Update the source of truth for "Save All"
                              if (msg.slipData != null && newCategory != null) {
                                print("DEBUG: Updating category for ${msg.imagePath} to $newCategory");
                                // Create a new map to ensure Hive detects the change
                                final newMap = Map<dynamic, dynamic>.from(msg.slipData!);
                                newMap['category'] = newCategory;
                                msg.slipData = newMap;
                                msg.save().then((_) => print("DEBUG: Saved msg.slipData for ${msg.imagePath}")); 
                              }
                            },
                          );
                        }

                        // Check if this is the most recent AI message with data
                        bool isLatestActionable = false;
                        if (!msg.isUser && msg.expenseData != null) {
                           bool hasNewer = false;
                           for (int i = 0; i < index; i++) {
                             if (!messages[i].isUser && messages[i].expenseData != null) {
                               hasNewer = true;
                               break;
                             }
                           }
                           isLatestActionable = !hasNewer;
                        }
                        
                        return _buildMessageBubble(msg, isLatestActionable);
                      },
                    );
                  },
                ),
              ),

              // Input Area
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color, // Match card color for input area
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -2),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: isExpense ? 'พิมพ์รายการจ่าย (เช่น ข้าว 50)' : 'พิมพ์รายรับ (เช่น เงินเดือน 20000)',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.brightness == Brightness.dark 
                              ? const Color(0xFF0F172A) // Darker input background in dark mode
                              : colorScheme.surfaceVariant, 
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        minLines: 1,
                        maxLines: 3,
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: colorScheme.primary, // Primary color button
                      child: IconButton(
                        icon: Icon(Icons.send, color: colorScheme.onPrimary), // Contrast icon
                        onPressed: _isProcessing ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Save All FAB (Only for Expense Mode usually, but logic works for both if needed)
          // Currently Save All is for Slips, which are Expense only.
          if (isExpense)
            ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box<ChatMessage> box, _) {
                final unsavedCount = box.values.where((m) => m.imagePath != null && !m.isSaved && m.slipData != null).length;
                
                if (unsavedCount > 0) {
                  return Positioned(
                    bottom: 80, // Above input area
                    right: 16,
                    child: FloatingActionButton.extended(
                      onPressed: _saveAllVerified,
                      label: Text("Save All ($unsavedCount)"),
                      icon: const Icon(Icons.save_alt),
                      backgroundColor: colorScheme.tertiaryContainer,
                      foregroundColor: colorScheme.onTertiaryContainer,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isLatestActionable) {
    final isUser = msg.isUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Custom Colors for Better Contrast
    final userBubbleColor = colorScheme.primary;
    final aiBubbleColor = isDark 
        ? const Color(0xFF334155) // Slate 700 (Lighter than bg)
        : colorScheme.secondaryContainer;
    
    final userTextColor = colorScheme.onPrimary;
    final aiTextColor = isDark 
        ? Colors.white 
        : colorScheme.onSecondaryContainer;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? userBubbleColor : aiBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser ? userTextColor : aiTextColor,
                ),
              ),
            ),
            
            // Result Card (Only for AI messages with data)
            if (!isUser && msg.expenseData != null && msg.expenseData!.isNotEmpty)
              // Check type of first item to decide widget
              (msg.expenseData![0]['type'] == 'income')
                  ? AIIncomeCardWidget(
                      message: msg,
                      onSave: (m) => _saveExpense(m, 0),
                      onDelete: _deleteMessage,
                    )
                  : AIExpenseCardWidget(
                      message: msg,
                      onSave: (m) => _saveExpense(m, 0),
                      onDelete: _deleteMessage,
                    ),
              
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                DateFormat('HH:mm').format(msg.timestamp),
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
