
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String businessName = 'THEE OLGAH MART';
  bool visible = false;
  bool navigated = false;

  @override
  void initState() {
    super.initState();
    loadName();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => visible = true);
    });
    Future.delayed(const Duration(milliseconds: 2800), goHome);
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
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: goHome,
        child: Center(
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 800),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_cart,
                      size: 96, color: Colors.white),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to',
                    style: TextStyle(fontSize: 22, color: Colors.white70),
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
                  const SizedBox(height: 40),
                  const Text(
                    'Tap anywhere to continue',
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}