import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_global_provider.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger initialization immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppGlobalProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to provider state
    final appProvider = context.watch<AppGlobalProvider>();

    // Check if AI is loaded
    if (appProvider.isAIModelLoaded) {
      // Navigate to Home Screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cool Icon or Logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology, // AI Brain Icon
                size: 64,
                color: Colors.indigoAccent,
              ),
            ),
            const SizedBox(height: 32),
            
            // Text
            const Text(
              "Waking up AI...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            
            // Subtitle (Optional status)
            Text(
              "Loading Model & Scanning Slips",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),

            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
            ),
          ],
        ),
      ),
    );
  }
}
