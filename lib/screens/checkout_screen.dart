import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/product.dart';
import '../models/customer.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<Product> products = [];
  List<Customer> customers = [];
  final Map<int, int> cart = {};
  final TextEditingController searchController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();
  String searchText = '';
  int? selectedCustomerId;
  String paymentMethod = 'Cash';
  String businessName = 'My Shop';
  String currency = 'UGX';
  bool discountEnabled = false;
  bool vatEnabled = false;
  double vatRate = 18;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    discountController.dispose();
    referenceController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final p = await DbHelper.instance.getProducts();
    final c = await DbHelper.instance.getCustomers();
    final name = await DbHelper.instance.getSetting('business_name');
    final cur = await DbHelper.instance.getSetting('currency');
    final disc = await DbHelper.instance.getSetting('discount_enabled');
    final vat = await DbHelper.instance.getSetting('vat_enabled');
    final rate = await DbHelper.instance.getSetting('vat_rate');
    setState(() {
      products = p;
      customers = c;
      businessName = name ?? 'My Shop';
      currency = cur ?? 'UGX';
      discountEnabled = disc == '1';
      vatEnabled = vat == '1';
      vatRate = double.tryParse(rate ?? '') ?? 18;
      if (!discountEnabled) discountController.clear();
    });
  }

  List<Product> get filteredProducts {
    if (searchText.isEmpty) return products;
    final query = searchText.toLowerCase();
    return products
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();
  }

  double get subtotal {
    double sum = 0;
    for (final p in products) {
      sum += p.price * (cart[p.id] ?? 0);
    }
    return sum;
  }

  double get discountPercent {
    if (!discountEnabled) return 0;
    final v = double.tryParse(discountController.text.trim()) ?? 0;
    return v.clamp(0, 100).toDouble();
  }

  double get discountAmount => subtotal * discountPercent / 100;

  double get vatAmount =>
      vatEnabled ? (subtotal - discountAmount) * vatRate / 100 : 0;

  double get grandTotal => subtotal - discountAmount + vatAmount;

  String money(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void addToCart(Product p) {
    final qty = cart[p.id] ?? 0;
    if (qty >= p.stock) {
      showMessage('Not enough stock for ${p.name}');
      return;
    }
    setState(() => cart[p.id!] = qty + 1);
  }

  void removeFromCart(Product p) {
    final qty = cart[p.id] ?? 0;
    if (qty <= 0) return;
    setState(() {
      if (qty == 1) {
        cart.remove(p.id);
      } else {
        cart[p.id!] = qty - 1;
      }
    });
  }

  Future<void> completeSale() async {
    if (cart.isEmpty) {
      showMessage('Cart is empty');
      return;
    }

    final isMobileMoney = paymentMethod == 'Mobile Money';
    final reference = referenceController.text.trim().toUpperCase();
    if (isMobileMoney && reference.length < 4) {
      showMessage('Enter the Mobile Money transaction ID (at least 4 characters)');
      return;
    }
    final String? savedReference = isMobileMoney ? reference : null;

    final sub = subtotal;
    final disc = discountAmount;
    final discPct = discountPercent;
    final vat = vatAmount;
    final grand = double.parse(grandTotal.toStringAsFixed(2));
    final method = paymentMethod;
    final items = <Map<String, dynamic>>[];
    final receiptLines = <String>[];

    for (final p in products) {
      final qty = cart[p.id] ?? 0;
      if (qty > 0) {
        items.add({'product_id': p.id, 'quantity': qty, 'price': p.price});
        receiptLines
            .add('${p.name} x$qty = $currency ${money(p.price * qty)}');
      }
    }

    String customerName = 'Walk-in customer';
    for (final c in customers) {
      if (c.id == selectedCustomerId) customerName = c.name;
    }

    await DbHelper.instance.saveSale(
      customerId: selectedCustomerId,
      total: grand,
      paymentMethod: method,
      reference: savedReference,
      items: items,
    );

    if (!mounted) return;
    setState(() {
      cart.clear();
      discountController.clear();
      referenceController.clear();
    });
    await loadData();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(businessName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('RECEIPT',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(DateTime.now().toString().substring(0, 16)),
            Text('Customer: $customerName'),
            const Divider(),
            ...receiptLines.map((line) => Text(line)),
            const Divider(),
            if (disc > 0 || vat > 0) Text('Subtotal: $currency ${money(sub)}'),
            if (disc > 0)
              Text('Discount (${money(discPct)}%): -$currency ${money(disc)}'),
            if (vat > 0)
              Text('VAT (${money(vatRate)}%): +$currency ${money(vat)}'),
            Text('TOTAL: $currency ${money(grand)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Paid by: $method'),
            if (savedReference != null)
              Text('Mobile Money ID: $savedReference'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = filteredProducts;

    return Scaffold(
      appBar: AppBar(title: Text('$businessName - Checkout')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchText.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    setState(() => searchText = '');
                  },
                ),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => searchText = value.trim()),
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text('No products. Add some in Inventory.'))
                : shown.isEmpty
                ? Center(child: Text('No product matches "$searchText"'))
                : ListView.builder(
              itemCount: shown.length,
              itemBuilder: (context, index) {
                final p = shown[index];
                final qty = cart[p.id] ?? 0;
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text(
                      'Price: $currency ${money(p.price)}  |  Stock: ${p.stock}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => removeFromCart(p),
                      ),
                      Text('$qty',
                          style: const TextStyle(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => addToCart(p),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int?>(
                        isExpanded: true,
                        value: selectedCustomerId,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Walk-in customer'),
                          ),
                          ...customers.map((c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.name),
                          )),
                        ],
                        onChanged: (v) =>
                            setState(() => selectedCustomerId = v),
                      ),
                    ),
                    if (discountEnabled) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: discountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Discount %',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Cash', label: Text('Cash')),
                    ButtonSegment(value: 'Card', label: Text('Card')),
                    ButtonSegment(
                        value: 'Mobile Money', label: Text('Mobile Money')),
                  ],
                  selected: {paymentMethod},
                  onSelectionChanged: (s) => setState(() {
                    paymentMethod = s.first;
                    if (paymentMethod != 'Mobile Money') {
                      referenceController.clear();
                    }
                  }),
                ),
                if (paymentMethod == 'Mobile Money')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextField(
                      controller: referenceController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Money transaction ID',
                        prefixIcon: Icon(Icons.phone_android),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                if (cart.isNotEmpty && (discountAmount > 0 || vatAmount > 0))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Subtotal ${money(subtotal)}'
                          '${discountAmount > 0 ? '  -  Discount ${money(discountAmount)}' : ''}'
                          '${vatAmount > 0 ? '  +  VAT ${money(vatAmount)}' : ''}',
                      style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: $currency ${money(grandTotal)}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    ElevatedButton(
                      onPressed: completeSale,
                      child: const Text('Charge'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}