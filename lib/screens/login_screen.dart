import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final pinController = TextEditingController();
  final confirmController = TextEditingController();
  bool loading = true;
  bool isSetup = false;
  bool locked = false;
  int attempts = 0;
  String? error;

  @override
  void initState() {
    super.initState();
    checkPin();
  }

  Future<void> checkPin() async {
    final has = await AuthService.hasPin();
    setState(() {
      isSetup = !has;
      loading = false;
    });
  }

  void goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  Future<void> submit() async {
    final pin = pinController.text.trim();

    if (pin.length < 4) {
      setState(() => error = 'PIN must be at least 4 digits');
      return;
    }

    if (isSetup) {
      if (pin != confirmController.text.trim()) {
        setState(() => error = 'PINs do not match');
        return;
      }
      await AuthService.setPin(pin);
      if (!mounted) return;
      goHome();
      return;
    }

    final ok = await AuthService.verifyPin(pin);
    if (!mounted) return;
    if (ok) {
      goHome();
      return;
    }

    attempts++;
    pinController.clear();
    if (attempts >= 3) {
      setState(() {
        locked = true;
        error = 'Too many wrong attempts. Wait 30 seconds.';
      });
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return;
      setState(() {
        locked = false;
        attempts = 0;
        error = null;
      });
    } else {
      setState(() => error = 'Wrong PIN. Attempts left: ${3 - attempts}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  isSetup ? 'Create a PIN' : 'Enter your PIN',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pinController,
                  obscureText: true,
                  enabled: !locked,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'PIN (4 to 6 digits)',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => submit(),
                ),
                if (isSetup) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Confirm PIN',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: locked ? null : submit,
                    child: Text(isSetup ? 'Save PIN' : 'Unlock'),
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