import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController walk;
  late final AnimationController travel;
  String businessName = 'THEE OLGAH MART';
  bool visible = false;
  bool navigated = false;
  bool started = false;

  @override
  void initState() {
    super.initState();
    walk = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
    travel = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
    travel.addStatusListener((status) {
      if (status == AnimationStatus.completed) goHome();
    });
    loadName();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => visible = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    final width = MediaQuery.of(context).size.width;
    final ms = ((width + 320) / 0.16).clamp(3500.0, 6500.0).round();
    travel.duration = Duration(milliseconds: ms);
    travel.forward();
  }

  @override
  void dispose() {
    walk.dispose();
    travel.dispose();
    super.dispose();
  }

  Future<void> loadName() async {
    final name = await DbHelper.instance.getSetting('business_name');
    if (!mounted) return;
    if (name != null && name.isNotEmpty) {
      setState(() => businessName = name);
    }
  }

  void goHome() {
    if (!mounted || navigated) return;
    navigated = true;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const groundHeight = 110.0;

    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: goHome,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              children: [
                Align(
                  alignment: const Alignment(0, -0.55),
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: const Duration(milliseconds: 800),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Welcome to',
                            style: TextStyle(
                                fontSize: 22, color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            businessName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: groundHeight,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1B5E20),
                      border: Border(
                        top: BorderSide(color: Color(0xFF66BB6A), width: 3),
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: travel,
                  builder: (context, child) {
                    final x = -290 + (width + 320) * travel.value;
                    return Positioned(
                      left: x,
                      bottom: groundHeight,
                      width: 260,
                      height: 190,
                      child: child!,
                    );
                  },
                  child: CustomPaint(painter: ShopperPainter(walk)),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 40,
                  child: Center(
                    child: Text(
                      'Tap anywhere to continue',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ShopperPainter extends CustomPainter {
  final Animation<double> cycle;

  ShopperPainter(this.cycle) : super(repaint: cycle);

  static const double groundY = 188;
  static const double thigh = 30;
  static const double shin = 30;

  double thighAngle(double theta) => 0.55 * math.sin(theta);

  double shinAngle(double theta) =>
      thighAngle(theta) - 0.8 * math.max(0.0, math.cos(theta));

  double extent(double theta) =>
      thigh * math.cos(thighAngle(theta)) + shin * math.cos(shinAngle(theta));

  Paint line(Color color, double width) => Paint()
    ..color = color
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  Paint fill(Color color) => Paint()..color = color;

  void drawLeg(Canvas canvas, double theta, Offset hip, Color color) {
    final t = thighAngle(theta);
    final s = shinAngle(theta);
    final knee = hip + Offset(math.sin(t) * thigh, math.cos(t) * thigh);
    final foot = knee + Offset(math.sin(s) * shin, math.cos(s) * shin);
    final path = Path()
      ..moveTo(hip.dx, hip.dy)
      ..lineTo(knee.dx, knee.dy)
      ..lineTo(foot.dx, foot.dy);
    canvas.drawPath(path, line(color, 9));
    canvas.drawOval(
      Rect.fromCenter(
          center: foot + const Offset(4, -1), width: 16, height: 7),
      fill(const Color(0xFF212121)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final phase = cycle.value * 2 * math.pi;
    const skin = Color(0xFF8D5524);
    const shirt = Color(0xFFFFC107);
    const hair = Color(0xFF1B1B1B);
    const bgGreen = Color(0xFF2E7D32);

    // Shadow on the ground
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(135, groundY + 1), width: 210, height: 9),
      fill(const Color(0x2E000000)),
    );

    // Groceries in the cart
    canvas.drawCircle(const Offset(136, 94), 9, fill(const Color(0xFFE53935)));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(150, 80, 22, 20), const Radius.circular(4)),
      fill(const Color(0xFFFFC107)),
    );
    canvas.drawCircle(const Offset(186, 93), 9, fill(const Color(0xFFFB8C00)));

    // Cart basket
    final basket = Path()
      ..moveTo(114, 100)
      ..lineTo(206, 100)
      ..lineTo(192, 154)
      ..lineTo(124, 154)
      ..close();
    canvas.drawPath(basket, fill(Colors.white));
    final grid = line(bgGreen, 3);
    for (final f in [0.25, 0.5, 0.75]) {
      canvas.drawLine(
          Offset(114 + 92 * f, 104), Offset(124 + 68 * f, 150), grid);
    }
    canvas.drawLine(const Offset(119, 127), const Offset(199, 127), grid);

    // Cart handle, frame and base
    final frame = line(Colors.white, 5);
    canvas.drawLine(const Offset(98, 100), const Offset(116, 100),
        line(Colors.white, 6));
    canvas.drawLine(const Offset(128, 154), const Offset(128, 163), frame);
    canvas.drawLine(const Offset(188, 154), const Offset(188, 163), frame);
    canvas.drawLine(const Offset(124, 163), const Offset(192, 163), frame);
    canvas.drawLine(const Offset(136, 163), const Offset(136, 177), frame);
    canvas.drawLine(const Offset(184, 163), const Offset(184, 177), frame);

    // Spinning wheels
    final wheelAngle = cycle.value * 4 * math.pi;
    for (final cx in [136.0, 184.0]) {
      final c = Offset(cx, 177);
      canvas.drawCircle(c, 9, line(Colors.white, 4));
      for (int i = 0; i < 4; i++) {
        final a = wheelAngle + i * math.pi / 2;
        canvas.drawLine(
          c,
          c + Offset(math.cos(a) * 8, math.sin(a) * 8),
          line(Colors.white, 2),
        );
      }
      canvas.drawCircle(c, 2.5, fill(Colors.white));
    }

    // The person
    final hipY = groundY - math.max(extent(phase), extent(phase + math.pi));
    final hip = Offset(58, hipY);
    drawLeg(canvas, phase + math.pi, hip, const Color(0xB3FFFFFF));
    drawLeg(canvas, phase, hip, Colors.white);

    final shoulder = Offset(hip.dx + 8, hip.dy - 44);
    canvas.drawLine(hip, shoulder, line(shirt, 15));

    const grip = Offset(102, 100);
    canvas.drawLine(shoulder, grip, line(skin, 7));
    canvas.drawCircle(grip, 4.5, fill(skin));

    final head = shoulder + const Offset(3, -17);
    canvas.drawCircle(head, 11, fill(skin));
    canvas.drawArc(
      Rect.fromCircle(center: head, radius: 11.5),
      math.pi * 0.85,
      math.pi * 0.95,
      true,
      fill(hair),
    );
    canvas.drawCircle(head + const Offset(5, -1), 1.6, fill(hair));
  }

  @override
  bool shouldRepaint(covariant ShopperPainter oldDelegate) => false;
}