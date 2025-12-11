import 'package:flutter/material.dart';

void showTopRightToast(BuildContext context, String message, {bool isError = false}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;
  final GlobalKey<_ToastWidgetState> key = GlobalKey<_ToastWidgetState>();

  void removeOverlay() {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  }

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: _ToastWidget(
          key: key,
          message: message,
          isError: isError,
          onDismissed: removeOverlay,
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // Auto-dismiss after 3 seconds
  Future.delayed(const Duration(seconds: 3), () {
    if (overlayEntry.mounted && key.currentState != null) {
      key.currentState!.dismiss();
    }
  });
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismissed;

  const _ToastWidget({
    super.key,
    required this.message,
    required this.isError,
    required this.onDismissed,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400), // Slightly slower for smoother slide
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // Slide from right (off-screen) to left
    _offset = Tween<Offset>(begin: const Offset(1.2, 0.0), end: Offset.zero).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  Future<void> dismiss() async {
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offset,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border(
              left: BorderSide(
                color: widget.isError ? Colors.red : Colors.green,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.isError ? Icons.error_outline : Icons.check_circle_outline,
                color: widget.isError ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                onPressed: dismiss, // Trigger reverse animation
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
