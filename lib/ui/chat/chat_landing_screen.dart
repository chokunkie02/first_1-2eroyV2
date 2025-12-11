import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/theme_service.dart';
import 'chat_conversation_screen.dart';

class ChatLandingScreen extends StatefulWidget {
  const ChatLandingScreen({super.key});

  @override
  State<ChatLandingScreen> createState() => _ChatLandingScreenState();
}

class _ChatLandingScreenState extends State<ChatLandingScreen> with SingleTickerProviderStateMixin {
  ChatMode? _selectedMode;
  late AnimationController _monkeyController;
  late Animation<double> _monkeyAnimation;

  @override
  void initState() {
    super.initState();
    _monkeyController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _monkeyAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _monkeyController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _monkeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedMode != null) {
      return PopScope(
        canPop: false, 
        onPopInvoked: (didPop) {
          if (didPop) return;
          setState(() {
            _selectedMode = null;
          });
        },
        child: ChatConversationScreen(
          mode: _selectedMode!,
          onBack: () {
            setState(() {
              _selectedMode = null;
            });
          },
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Center(
                child: Text(
                  'ข้อความ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Kanit',
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            
            // Hero Section (Welcome)
            _buildHeroSection(context),

            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildAnimatedItem(
                          delay: 200,
                          child: _buildCleanChatCard(
                            context,
                            title: "บันทึกรายจ่าย",
                            subtitle: "สแกนสลิป หรือพิมพ์รายการ",
                            icon: Icons.receipt_long_rounded,
                            color: Colors.redAccent,
                            mode: ChatMode.expense,
                          ),
                        ),
                        
                        _buildAnimatedItem(
                          delay: 400,
                          child: _buildCleanChatCard(
                            context,
                            title: "บันทึกรายรับ",
                            subtitle: "บันทึกเงินเดือน หรือรายได้อื่นๆ",
                            icon: Icons.savings_rounded,
                            color: Colors.green,
                            mode: ChatMode.income,
                          ),
                        ),
                        
                        // Spacer for monkey area
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                  
                  // Moving Pixel Monkey
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: AnimatedBuilder(
                      animation: _monkeyAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _monkeyAnimation.value),
                          child: Column(
                            children: [
                              Opacity(
                                opacity: 0.8,
                                child: Image.asset(
                                  'assets/images/pixel_monkey_animated.png', // Ensure this path matches where you put the file
                                  width: 80,
                                  height: 80,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.pets, size: 60, color: Colors.grey); // Fallback
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "น้องลิงรอคุยอยู่นะ...",
                                style: TextStyle(
                                  fontFamily: 'Kanit',
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.waving_hand, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "สวัสดีครับ!",
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "วันนี้ให้ผมช่วยจดอะไรดี?",
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedItem({required int delay, required Widget child}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, double value, _) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0), // Fix: Clamp opacity to avoid assertion error with easeOutBack
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildCleanChatCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required ChatMode mode,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedMode = mode;
            });
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Kanit',
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Kanit',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
