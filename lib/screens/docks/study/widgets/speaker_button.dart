import 'package:flutter/material.dart';
import 'package:vocab_ai/screens/docks/study/service/text_to_speech_service.dart';


class SpeakerButton extends StatefulWidget {
  final String text;
  final double size;
  final Color? color;
  final Color? activeColor;

  const SpeakerButton({
    Key? key,
    required this.text,
    this.size = 40,
    this.color,
    this.activeColor,
  }) : super(key: key);

  @override
  State<SpeakerButton> createState() => _SpeakerButtonState();
}

class _SpeakerButtonState extends State<SpeakerButton>
    with SingleTickerProviderStateMixin {
  final TextToSpeechService _tts = TextToSpeechService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    // Animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Speak
    setState(() => _isSpeaking = true);
    await _tts.speak(widget.text);

    // Đợi một chút để animation mượt hơn
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() => _isSpeaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Colors.purple;
    final normalColor = widget.color ?? Colors.grey[600]!;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(widget.size / 2),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isSpeaking
                  ? activeColor.withOpacity(0.1)
                  : Colors.transparent,
              border: Border.all(
                color: _isSpeaking ? activeColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Icon loa
                Icon(
                  _isSpeaking ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                  size: widget.size * 0.5,
                  color: _isSpeaking ? activeColor : normalColor,
                ),

                // Animation sóng âm
                if (_isSpeaking)
                  Positioned.fill(
                    child: _SoundWaveAnimation(
                      color: activeColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget animation sóng âm thanh
class _SoundWaveAnimation extends StatefulWidget {
  final Color color;

  const _SoundWaveAnimation({required this.color});

  @override
  State<_SoundWaveAnimation> createState() => _SoundWaveAnimationState();
}

class _SoundWaveAnimationState extends State<_SoundWaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _SoundWavePainter(
            progress: _animation.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _SoundWavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _SoundWavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 2; i++) {
      final normalizedProgress = (progress + i * 0.5) % 1.0;
      final radius = maxRadius * normalizedProgress;
      final opacity = (1.0 - normalizedProgress) * 0.3;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SoundWavePainter oldDelegate) => true;
}