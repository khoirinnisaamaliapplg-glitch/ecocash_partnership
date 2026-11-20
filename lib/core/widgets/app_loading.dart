import 'dart:math' as math;
import 'package:flutter/material.dart';

class AppLoading extends StatefulWidget {
  final String message;
  final double size;

  const AppLoading({
    super.key,
    this.message = 'Sedang memuat data...',
    this.size = 76,
  });

  @override
  State<AppLoading> createState() => _AppLoadingState();
}

class _AppLoadingState extends State<AppLoading> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _dotController;

  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  static const Color navy = Color(0xFF172B4D);
  static const Color cyan = Color(0xFF19B8D4);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.65, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animasi tulisan EcoCash Partner
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Eco',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 31,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Cash',
                              style: TextStyle(
                                color: Color(0xFFFACC15),
                                fontSize: 31,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 2),
                      const Text(
                        'PARTNER',
                        style: TextStyle(
                          color: navy,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 22),

          // Keterangan loading
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: navy.withValues(alpha: 0.65),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 14),

          // Animasi tiga titik
          AnimatedBuilder(
            animation: _dotController,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final phase =
                      (_dotController.value - index * 0.22) * 2 * math.pi;

                  final wave = (math.sin(phase) + 1) / 2;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 7,
                    height: 7,
                    transform: Matrix4.identity()..scale(0.8 + (wave * 0.4)),
                    decoration: BoxDecoration(
                      color: cyan.withValues(alpha: 0.35 + (wave * 0.65)),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
