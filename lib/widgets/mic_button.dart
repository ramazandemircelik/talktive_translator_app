import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class MicButton extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  const MicButton({
    super.key,
    required this.isListening,
    required this.isProcessing,
    required this.onPressed,
    this.onLongPress,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isListening) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isProcessing ? null : widget.onPressed,
      onLongPress: widget.isProcessing ? null : widget.onLongPress,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isListening ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isListening
                      ? [
                          Colors.red.shade400,
                          Colors.red.shade600,
                        ]
                      : widget.isProcessing
                          ? [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ]
                          : [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primaryContainer,
                            ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isListening
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary)
                        .withOpacity(0.3),
                    blurRadius: widget.isListening ? 20 : 10,
                    spreadRadius: widget.isListening ? 5 : 2,
                  ),
                ],
              ),
              child: widget.isProcessing
                  ? SpinKitWave(
                      color: Colors.white,
                      size: 30,
                    )
                  : Icon(
                      widget.isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 32,
                    ),
            ),
          );
        },
      ),
    );
  }
}
