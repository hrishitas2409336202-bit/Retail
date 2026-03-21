import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  String _errorMessage = '';
  bool _obsPass = true;
  bool _isLoggingIn = false;

  late AnimationController _particleController;
  late AnimationController _logoController;
  late AnimationController _slideController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _slideController, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 200), () {
      _logoController.forward();
      Future.delayed(const Duration(milliseconds: 500),
          () => _slideController.forward());
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _logoController.dispose();
    _slideController.dispose();
    _idController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final size = MediaQuery.of(context).size;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Animated particle background ──
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) => CustomPaint(
              size: size,
              painter: _ParticlePainter(_particleController.value),
            ),
          ),

          // ── Gradient blobs ──
          Positioned(
            top: -80,
            left: -80,
            child: _blob(const Color(0xFF6C63FF), 300, 0.18),
          ),
          Positioned(
            top: size.height * 0.3,
            right: -60,
            child: _blob(const Color(0xFF00D4FF), 200, 0.12),
          ),
          Positioned(
            bottom: -60,
            left: size.width * 0.2,
            child: _blob(const Color(0xFF7C3AED), 250, 0.14),
          ),

          // ── Main content ──
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _glassChip(
                        onTap: state.toggleTheme,
                        child: Icon(
                          state.themeMode == ThemeMode.dark
                              ? LucideIcons.sun
                              : LucideIcons.moon,
                          color: isDark ? Colors.white70 : Colors.black87,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // ── LOGO + Brand ──
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Column(
                      children: [
                        // Glowing logo
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.5),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.shoppingBag,
                              size: 48, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                          ).createShader(b),
                          child: Text('RetailIQ',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -1,
                              )),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Smart Retail Intelligence Platform',
                          style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black54,
                              fontSize: 13,
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 20),
                        // Feature pills
                        Wrap(
                          spacing: 8,
                          children: [
                            _featurePill('🧠 AI Powered'),
                            _featurePill('📊 Real-time Analytics'),
                            _featurePill('📦 Smart Inventory'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ── Role cards ──
                SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _slideController,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select your role to continue',
                            style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontSize: 13,
                                letterSpacing: 0.3),
                          ),
                          const SizedBox(height: 16),
                          _roleCard(
                            context,
                            state,
                            icon: LucideIcons.layoutDashboard,
                            title: 'Store Owner',
                            subtitle:
                                'Full access · Analytics · AI Advisor · Suppliers',
                            role: UserRole.admin,
                            gradient: const [Color(0xFF6C63FF), Color(0xFF4A42D6)],
                            glowColor: const Color(0xFF6C63FF),
                            badge: 'ADMIN',
                          ),
                          const SizedBox(height: 14),
                          _roleCard(
                            context,
                            state,
                            icon: LucideIcons.scanLine,
                            title: 'Staff / Cashier',
                            subtitle: 'Billing · Scanner · Inventory lookup',
                            role: UserRole.staff,
                            gradient: const [Color(0xFF0F766E), Color(0xFF0D6353)],
                            glowColor: const Color(0xFF10B981),
                            badge: 'STAFF',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Footer
                Text('Powered by RetailIQ AI  •  v2.0',
                    style: TextStyle(
                        color: isDark ? Colors.white.withOpacity(0.18) : Colors.black26,
                        fontSize: 11)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }

  Widget _glassChip({required Widget child, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black12),
        ),
        child: child,
      ),
    );
  }

  Widget _featurePill(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black12),
      ),
      child: Text(text,
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
    );
  }

  Widget _roleCard(
    BuildContext context,
    AppState state, {
    required IconData icon,
    required String title,
    required String subtitle,
    required UserRole role,
    required List<Color> gradient,
    required Color glowColor,
    required String badge,
  }) {
    return GestureDetector(
      onTap: () => _showLoginDialog(context, state, role, gradient),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [gradient[0].withOpacity(0.3), gradient[1].withOpacity(0.15)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: gradient[0].withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: gradient[0].withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: gradient[0].withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(badge,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(LucideIcons.arrowRight, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context, AppState state, UserRole role,
      List<Color> gradient) {
    _idController.clear();
    _passController.clear();
    _errorMessage = '';
    _obsPass = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bsCtx) {
        return StatefulBuilder(builder: (bsCtx, setSheet) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(bsCtx).viewInsets.bottom + 24,
              top: 8,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2))),
                ),
                // Role header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          borderRadius: BorderRadius.circular(14)),
                      child: Icon(
                        role == UserRole.admin
                            ? LucideIcons.layoutDashboard
                            : LucideIcons.scanLine,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role == UserRole.admin
                              ? 'Store Owner Login'
                              : 'Staff / Cashier Login',
                          style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          role == UserRole.admin
                              ? 'ID: admin  •  Pass: admin123'
                              : 'ID: staff  •  Pass: staff123',
                          style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Fields
                _darkField('Login ID', _idController, LucideIcons.user,
                    gradient[0]),
                const SizedBox(height: 14),
                _darkPasswordField(
                    'Password', _passController, gradient[0], () {
                  setSheet(() => _obsPass = !_obsPass);
                }),

                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.redAccent.withOpacity(0.3))),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle,
                            color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Text(_errorMessage,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),

                // Login button
                StatefulBuilder(builder: (ctx, setSelf) {
                  return GestureDetector(
                    onTap: () async {
                      final id = _idController.text.trim();
                      final pass = _passController.text.trim();
                      final isAdminCreds =
                          id == 'admin' && pass == 'admin123';
                      final isStaffCreds =
                          id == 'staff' && pass == 'staff123';

                      if (role == UserRole.admin) {
                        if (isAdminCreds) {
                          setSelf(() => _isLoggingIn = true);
                          await Future.delayed(
                              const Duration(milliseconds: 600));
                          if (!context.mounted) return;
                          Navigator.pop(bsCtx);
                          state.login(UserRole.admin);
                        } else {
                          setSheet(() => _errorMessage =
                              '❌ Invalid admin credentials');
                        }
                      } else {
                        if (isStaffCreds || isAdminCreds) {
                          setSelf(() => _isLoggingIn = true);
                          await Future.delayed(
                              const Duration(milliseconds: 600));
                          if (!context.mounted) return;
                          Navigator.pop(bsCtx);
                          state.login(UserRole.staff);
                        } else {
                          setSheet(() =>
                              _errorMessage = '❌ Invalid credentials');
                        }
                      }
                    },
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: gradient[0].withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Center(
                        child: _isLoggingIn
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text('SIGN IN',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1.2)),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _darkField(String label, TextEditingController controller,
      IconData icon, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black45),
        prefixIcon: Icon(icon, color: accent.withOpacity(0.7), size: 18),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12)),

        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accent)),
      ),
    );
  }

  Widget _darkPasswordField(String label, TextEditingController controller,
      Color accent, VoidCallback onToggle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: _obsPass,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black45),
        prefixIcon:
            Icon(LucideIcons.lock, color: accent.withOpacity(0.7), size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            _obsPass ? LucideIcons.eye : LucideIcons.eyeOff,
            color: isDark ? Colors.white38 : Colors.black45,
            size: 18,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accent)),
      ),
    );
  }
}

// ─── Particle Painter ───────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double progress;
  static final List<_Particle> _particles = List.generate(
      40, (i) => _Particle(seed: i));

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress + p.offset) % 1.0;
      final x = p.x * size.width;
      final y = (p.y + t * p.speed) % 1.0 * size.height;
      final opacity = (math.sin(t * math.pi) * 0.4).clamp(0.0, 0.4);
      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

class _Particle {
  final double x;
  final double y;
  final double speed;
  final double radius;
  final double offset;
  final Color color;

  _Particle({required int seed})
      : x = (seed * 37 % 100) / 100.0,
        y = (seed * 53 % 100) / 100.0,
        speed = 0.08 + (seed % 5) * 0.02,
        radius = 1.0 + (seed % 3) * 1.0,
        offset = (seed * 17 % 100) / 100.0,
        color = seed % 3 == 0
            ? const Color(0xFF6C63FF)
            : seed % 3 == 1
                ? const Color(0xFF00D4FF)
                : const Color(0xFF7C3AED);
}

