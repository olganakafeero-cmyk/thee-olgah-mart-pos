import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../services/theme_controller.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final nameController = TextEditingController();
  final currencyController = TextEditingController();
  final vatRateController = TextEditingController();
  final ThemeController theme = ThemeController.instance;
  bool discountEnabled = false;
  bool vatEnabled = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final name = await DbHelper.instance.getSetting('business_name');
    final currency = await DbHelper.instance.getSetting('currency');
    final disc = await DbHelper.instance.getSetting('discount_enabled');
    final vat = await DbHelper.instance.getSetting('vat_enabled');
    final rate = await DbHelper.instance.getSetting('vat_rate');
    setState(() {
      nameController.text = name ?? 'My Shop';
      currencyController.text = currency ?? 'UGX';
      vatRateController.text = rate ?? '18';
      discountEnabled = disc == '1';
      vatEnabled = vat == '1';
    });
  }

  Future<void> saveSettings() async {
    final name = nameController.text.trim();
    final currency = currencyController.text.trim().toUpperCase();
    final vatRate = double.tryParse(vatRateController.text.trim());

    if (name.isEmpty || currency.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill the name and currency')),
      );
      return;
    }

    if (vatRate == null || vatRate < 0 || vatRate > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('VAT rate must be between 0 and 100')),
      );
      return;
    }

    await DbHelper.instance.setSetting('business_name', name);
    await DbHelper.instance.setSetting('currency', currency);
    await DbHelper.instance.setSetting('vat_rate', vatRate.toString());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  Future<void> saveSwitch(String key, bool value) async {
    await DbHelper.instance.setSetting(key, value ? '1' : '0');
  }

  void lockApp() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.phone_iphone),
              ),
            ],
            selected: {theme.themeMode},
            onSelectionChanged: (s) async {
              await theme.setMode(s.first);
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 16),
          const Text('Theme colour'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ThemeController.colors.entries.map((entry) {
              final selected = theme.colorName == entry.key;
              return GestureDetector(
                onTap: () async {
                  await theme.setColor(entry.key);
                  if (mounted) setState(() {});
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: entry.value,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const Divider(height: 40),
          const Text(
            'Business details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Business name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: currencyController,
            decoration: const InputDecoration(
              labelText: 'Currency (for example UGX, KES, USD)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: vatRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'VAT rate (%)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: saveSettings,
            child: const Text('Save settings'),
          ),
          const Divider(height: 40),
          const Text(
            'Sales options',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Allow discounts'),
            subtitle: const Text('Shows a discount % box at Checkout'),
            value: discountEnabled,
            onChanged: (value) {
              setState(() => discountEnabled = value);
              saveSwitch('discount_enabled', value);
            },
          ),
          SwitchListTile(
            title: const Text('Add VAT to sales'),
            subtitle: const Text('Adds the VAT rate above to every sale'),
            value: vatEnabled,
            onChanged: (value) {
              setState(() => vatEnabled = value);
              saveSwitch('vat_enabled', value);
            },
          ),
          const Divider(height: 40),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Lock app'),
            subtitle: const Text('Return to the PIN screen'),
            onTap: lockApp,
          ),
        ],
      ),
    );
  }
}