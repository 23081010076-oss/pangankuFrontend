import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
      ),
    );
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF388E3C),
              Color(0xFF43A047),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo box
                      Transform.scale(
                        scale: _scaleAnim.value,
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: CustomPaint(
                                size: const Size(64, 64),
                                painter: _WheatPainter(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: const Text(
                          'SIPKAP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Text(
                          'Sistem Informasi Ketahanan Pangan',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Text(
                          'Kabupaten Lamongan',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Progress bar
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 60),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _progressAnim.value,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Memuat aplikasi...',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // Center wheat stalk
    final stalkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy - 4),
      Offset(center.dx, size.height - 4),
      stalkPaint,
    );

    // Center grain
    final path1 = Path()
      ..moveTo(center.dx, 4)
      ..cubicTo(center.dx - 4, 10, center.dx - 4, 16, center.dx, 20)
      ..cubicTo(center.dx + 4, 16, center.dx + 4, 10, center.dx, 4);
    paint.color = Colors.white.withValues(alpha: 0.9);
    canvas.drawPath(path1, paint);

    // Left grain
    final path2 = Path()
      ..moveTo(center.dx - 10, 9)
      ..cubicTo(center.dx - 13, 16, center.dx - 11, 22, center.dx - 7, 23)
      ..cubicTo(center.dx - 5, 19, center.dx - 7, 13, center.dx - 10, 9);
    paint.color = Colors.white.withValues(alpha: 0.8);
    canvas.drawPath(path2, paint);

    // Right grain
    final path3 = Path()
      ..moveTo(center.dx + 10, 9)
      ..cubicTo(center.dx + 13, 16, center.dx + 11, 22, center.dx + 7, 23)
      ..cubicTo(center.dx + 5, 19, center.dx + 7, 13, center.dx + 10, 9);
    paint.color = Colors.white.withValues(alpha: 0.8);
    canvas.drawPath(path3, paint);

    // Wheat leaves
    final path4 = Path()
      ..moveTo(center.dx - 17, 18)
      ..cubicTo(center.dx - 16, 24, center.dx - 11, 28, center.dx - 7, 28)
      ..cubicTo(center.dx - 7, 23, center.dx - 12, 19, center.dx - 17, 18);
    paint.color = Colors.white.withValues(alpha: 0.7);
    canvas.drawPath(path4, paint);

    final path5 = Path()
      ..moveTo(center.dx + 17, 18)
      ..cubicTo(center.dx + 16, 24, center.dx + 11, 28, center.dx + 7, 28)
      ..cubicTo(center.dx + 7, 23, center.dx + 12, 19, center.dx + 17, 18);
    paint.color = Colors.white.withValues(alpha: 0.7);
    canvas.drawPath(path5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
