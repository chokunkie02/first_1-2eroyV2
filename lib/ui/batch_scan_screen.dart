import 'dart:io';
import 'package:flutter/material.dart';
import '../services/slip_scanner_service.dart';
import '../services/database_service.dart';
import '../services/scan_history_service.dart';
import 'widgets/slip_card.dart';

class BatchScanScreen extends StatefulWidget {
  final List<File> imageFiles;
  final String? albumId; // To update history

  const BatchScanScreen({super.key, required this.imageFiles, this.albumId});

  @override
  State<BatchScanScreen> createState() => _BatchScanScreenState();
}

class _BatchScanScreenState extends State<BatchScanScreen> {
  final SlipScannerService _scanner = SlipScannerService();
  final DatabaseService _db = DatabaseService();
  final ScanHistoryService _historyService = ScanHistoryService();

  // State
  List<File> _queue = [];
  Map<String, SlipData?> _results = {}; // Map file path to result
  Map<String, bool> _isSaved = {}; // Map file path to saved status
  Map<String, String> _categories = {}; // Map file path to selected category
  
  // Processing status
  int _processedCount = 0;
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _queue = List.from(widget.imageFiles);
    _startBatchProcessing();
  }

  Future<void> _startBatchProcessing() async {
    for (final file in _queue) {
      if (!mounted) return;
      
      try {
        // Process one by one
        final slip = await _scanner.processImageFile(file);
        
        if (mounted) {
          setState(() {
            _results[file.path] = slip; // Can be null if failed
            _processedCount++;
          });
        }
      } catch (e) {
        print("Error processing ${file.path}: $e");
        if (mounted) {
          setState(() {
            _results[file.path] = null; // Mark as failed
            _processedCount++;
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Batch Scan (${_processedCount}/${widget.imageFiles.length})"),
        actions: [
          if (!_isProcessing)
            TextButton.icon(
              onPressed: _saveAllVerified,
              icon: const Icon(Icons.save_alt, color: Colors.white),
              label: const Text("Save All", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: widget.imageFiles.length,
        itemBuilder: (context, index) {
          final file = widget.imageFiles[index];
          final path = file.path;

          // 1. Not processed yet
          if (!_results.containsKey(path)) {
            return _buildProcessingCard(file);
          }

          final slip = _results[path];

          // 2. Failed to process
          if (slip == null) {
            return _buildErrorCard(file);
          }

          // 3. Success -> Show SlipCard
          return SlipCardWidget(
            key: ValueKey(path),
            imageFile: file,
            initialData: slip,
            isSaved: _isSaved[path] ?? false,
            onDelete: () {
              setState(() {
                widget.imageFiles.removeAt(index);
                _results.remove(path);
                _isSaved.remove(path);
              });
            },
            onSave: (updatedSlip, category) async {
              await _saveSingleSlip(path, updatedSlip, category);
            },
          );
        },
      ),
    );
  }

  Widget _buildProcessingCard(File file) {
    return Card(
      color: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: const CircularProgressIndicator(),
        title: const Text("Processing..."),
        subtitle: Text(file.path.split('/').last),
      ),
    );
  }

  Widget _buildErrorCard(File file) {
    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: const Icon(Icons.error, color: Colors.red),
        title: const Text("Could not read slip"),
        subtitle: Text(file.path.split('/').last),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              widget.imageFiles.remove(file);
              _results.remove(file.path);
            });
          },
        ),
      ),
    );
  }

  Future<void> _saveSingleSlip(String path, SlipData slip, String category) async {
    await _db.addTransaction(
      slip.bank,
      slip.amount,
      category: category,
      qty: 1.0,
      date: slip.date,
      note: slip.memo,
    );

    setState(() {
      _isSaved[path] = true;
      _results[path] = slip; // Update with edited data
      _categories[path] = category;
    });
  }

  Future<void> _saveAllVerified() async {
    int savedCount = 0;
    for (final file in widget.imageFiles) {
      final path = file.path;
      // If processed, valid, and not yet saved
      if (_results.containsKey(path) && _results[path] != null && !(_isSaved[path] ?? false)) {
        // Use current data (user might have edited it but not clicked save yet? 
        // Ideally we should track edits. For now, use the result data.
        // NOTE: If user edited text fields but didn't click save, those edits are local to the widget state.
        // To support "Save All" with edits, we'd need to lift state up or use controllers.
        // For this MVP, "Save All" saves the *initial* or *individually saved* state.
        // Actually, let's just save the initial OCR data if not edited. 
        // If user wants to edit, they should use individual save or we need complex state management.
        // Let's stick to: Save All saves whatever is in _results[path].
        
        await _saveSingleSlip(path, _results[path]!, _categories[path] ?? 'Uncategorized');
        savedCount++;
      }
    }

    if (savedCount > 0) {
      if (widget.albumId != null) {
        await _historyService.updateLastScanTime(widget.albumId!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Batch saved $savedCount slips!")),
        );
        Navigator.pop(context); // Go back to Home
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No new slips to save.")),
        );
      }
    }
  }
}
