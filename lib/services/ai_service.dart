import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'llm_isolate_service.dart';

class AIService {
  // Singleton Pattern
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final LLMIsolateService _isolateService = LLMIsolateService();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final modelPath = await _getModelPath();
    await _isolateService.initialize(modelPath);
    _isInitialized = true;
    print("[AIService] Initialized successfully.");
  }

  Stream<String> processStep(String input, String promptTemplate) {
    // Replace {input} in prompt
    final fullPrompt = promptTemplate.replaceFirst("{input}", input);

    // 🔥 [DEBUG] LOG THE EXACT PROMPT
    print("--------------------------------------------------");
    print("[CHECK PROMPT] ACTUAL PROMPT SENT TO AI:");
    print(fullPrompt); 
    print("--------------------------------------------------");
    
    return _isolateService.generateStream(fullPrompt);
  }

  Future<String> _getModelPath() async {
    // Unified logic for ALL platforms (Mobile & Linux)
    final directory = await getApplicationDocumentsDirectory();
    final modelPath = '${directory.path}/model-unsloth21.Q4_0.gguf';
    
    final file = File(modelPath);
    
    // Only copy if file doesn't exist
    if (!await file.exists()) {
      print("[AI_DEBUG] Copying fresh model from assets...");
      try {
        final byteData = await rootBundle.load('assets/models/model-unsloth21.Q4_0.gguf');
        await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
        print("[AI_DEBUG] Model copied successfully to $modelPath");
      } catch (e) {
        print("[AI_DEBUG] Error copying model: $e");
        throw e;
      }
    } else {
      print("[AI_DEBUG] Model found at $modelPath");
    }
    return modelPath;
  }
}
