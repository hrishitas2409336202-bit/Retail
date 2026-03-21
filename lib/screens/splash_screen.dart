import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'login_screen.dart';
import 'admin/store_command_center.dart';
import 'staff/staff_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _exitController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _exitScale;
  late Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();

    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _exitController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeIn));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _exitScale = Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: _exitController, curve: Curves.easeIn));
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitController, curve: Curves.easeIn));

    _runSequence();
  }

  void _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    _exitController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final state = context.read<AppState>();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) {
          if (state.currentRole == null) return const LoginScreen();
          if (state.currentRole == UserRole.admin) return const StoreCommandCenter();
          return const StaffDashboard();
        },
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _ringController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060818),
      body: FadeTransition(
        opacity: _exitOpacity,
        child: ScaleTransition(
          scale: _exitScale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background gradient blobs
              Positioned(
                top: -100,
                left: -100,
                child: _blob(const Color(0xFF6C63FF), 350, 0.2),
              ),
              Positioned(
                bottom: -80,
                right: -80,
                child: _blob(const Color(0xFF00D4FF), 280, 0.15),
              ),

              // Center content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rotating rings + logo
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer spinning ring
                        AnimatedBuilder(
                          animation: _ringController,
                          builder: (_, __) => Transform.rotate(
                            angle: _ringController.value * 2 * math.pi,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF6C63FF).withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                              child: CustomPaint(
                                painter: _ArcPainter(
                                  color: const Color(0xFF6C63FF),
                                  progress: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Inner spinning ring (opposite)
                        AnimatedBuilder(
                          animation: _ringController,
                          builder: (_, __) => Transform.rotate(
                            angle: -_ringController.value * 2 * math.pi,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF00D4FF).withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: CustomPaint(
                                painter: _ArcPainter(
                                  color: const Color(0xFF00D4FF),
                                  progress: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Logo
                        ScaleTransition(
                          scale: _logoScale,
                          child: FadeTransition(
                            opacity: _logoOpacity,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6C63FF),
                                    Color(0xFF00D4FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color(0xFF6C63FF).withOpacity(0.6),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.shopping_bag_rounded,
                                  color: Colors.white, size: 38),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Brand name
                  FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                          ).createShader(b),
                          child: const Text(
                            'RetailIQ',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Smart Retail Intelligence Platform',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Feature highlights
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _chip('🧠 AI', const Color(0xFF6C63FF)),
                            const SizedBox(width: 8),
                            _chip('📊 Analytics', const Color(0xFF00D4FF)),
                            const SizedBox(width: 8),
                            _chip('📦 Inventory', const Color(0xFF10B981)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Bottom: loading dots
              Positioned(
                bottom: 60,
                child: FadeTransition(
                  opacity: _textOpacity,
                  child: _LoadingDots(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blob(Color color, double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(opacity)),
      );

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      );
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double progress;
  _ArcPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      0,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => false;
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_ctrl.value * 3 - i).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * math.sin(t * math.pi);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6C63FF).withOpacity(0.5 + 0.5 * scale),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

