import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import '../models/customer.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pos.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
      onOpen: (db) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS settings (
            name TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        final cols = await db.rawQuery('PRAGMA table_info(sales)');
        final hasReference = cols.any((c) => c['name'] == 'reference');
        if (!hasReference) {
          await db.execute('ALTER TABLE sales ADD COLUMN reference TEXT');
        }
      },
    );
  }
  Future _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL
      )
    ''');
  }

  // ---------- PRODUCTS ----------
  Future<int> addProduct(Product p) async {
    final db = await database;
    return await db.insert('products', p.toMap());
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final result = await db.query('products', orderBy: 'name');
    return result.map((m) => Product.fromMap(m)).toList();
  }

  Future<int> updateProduct(Product p) async {
    final db = await database;
    return await db.update('products', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- CUSTOMERS ----------
  Future<int> addCustomer(Customer c) async {
    final db = await database;
    return await db.insert('customers', c.toMap());
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final result = await db.query('customers', orderBy: 'name');
    return result.map((m) => Customer.fromMap(m)).toList();
  }
  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
  // ---------- SALES ----------
  Future<int> saveSale({
    int? customerId,
    required double total,
    required String paymentMethod,
    String? reference,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      final saleId = await txn.insert('sales', {
        'customer_id': customerId,
        'total': total,
        'payment_method': paymentMethod,
        'reference': reference,
        'date': DateTime.now().toIso8601String(),
      });
      for (final item in items) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'price': item['price'],
        });
        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item['quantity'], item['product_id']],
        );
      }
      return saleId;
    });
  }

  // ---------- REPORTS ----------
  Future<Map<String, dynamic>> getTodaySummary() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(total), 0) AS total, COUNT(*) AS count '
          'FROM sales WHERE substr(date, 1, 10) = ?',
      [today],
    );
    return result.first;
  }

  Future<List<Map<String, dynamic>>> getSalesByDay() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT substr(date, 1, 10) AS day, SUM(total) AS total
      FROM sales
      GROUP BY day
      ORDER BY day DESC
      LIMIT 7
    ''');
  }

  Future<List<Map<String, dynamic>>> getSalesByPayment() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT payment_method, SUM(total) AS total, COUNT(*) AS count
      FROM sales
      GROUP BY payment_method
    ''');
  }

  Future<List<Map<String, dynamic>>> getTopProducts() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.name AS name,
             SUM(si.quantity) AS qty,
             SUM(si.quantity * si.price) AS revenue
      FROM sale_items si
      JOIN products p ON p.id = si.product_id
      GROUP BY si.product_id
      ORDER BY qty DESC
      LIMIT 5
    ''');
  }
  Future<List<Product>> getLowStockProducts({int threshold = 5}) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'stock <= ?',
      whereArgs: [threshold],
      orderBy: 'stock ASC, name',
    );
    return result.map((m) => Product.fromMap(m)).toList();
  }
  // ---------- SETTINGS ----------
  Future<String?> getSetting(String name) async {
    final db = await database;
    final result =
    await db.query('settings', where: 'name = ?', whereArgs: [name]);
    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  Future<void> setSetting(String name, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'name': name, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}