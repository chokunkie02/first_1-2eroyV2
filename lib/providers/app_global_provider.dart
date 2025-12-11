import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/slip_scanner_service.dart';

class AppGlobalProvider extends ChangeNotifier {
  final AIService _aiService = AIService();
  final SlipScannerService _scannerService = SlipScannerService();

  bool _isAIModelLoaded = false;
  bool get isAIModelLoaded => _isAIModelLoaded;

  List<SlipData> _pendingSlips = [];
  List<SlipData> get pendingSlips => _pendingSlips;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  Future<void> initialize() async {
    print("[AppGlobalProvider] Initializing...");
    
    // 1. Initialize AI (Background)
    _initAI();

    // 2. Auto-Scan Slips (Background)
    _autoScanSlips();
  }

  Future<void> _initAI() async {
    try {
      await _aiService.initialize();
      _isAIModelLoaded = true;
      notifyListeners();
      print("[AppGlobalProvider] AI Model Loaded.");
    } catch (e) {
      print("[AppGlobalProvider] AI Init Error: $e");
    }
  }

  Future<void> _autoScanSlips() async {
    if (_isScanning) return;
    _isScanning = true;
    notifyListeners();

    try {
      print("[AppGlobalProvider] Starting Auto-Scan...");
      final slips = await _scannerService.scanNewSlips();
      if (slips.isNotEmpty) {
        _pendingSlips.addAll(slips);
        print("[AppGlobalProvider] Found ${slips.length} new slips.");
      } else {
        print("[AppGlobalProvider] No new slips found.");
      }
    } catch (e) {
      print("[AppGlobalProvider] Auto-Scan Error: $e");
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  void clearPendingSlips() {
    _pendingSlips.clear();
    notifyListeners();
  }
}
