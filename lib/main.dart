import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart'; // For date and time formatting

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tailoring App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TailoringApp(),
    );
  }
}

class TailoringApp extends StatefulWidget {
  const TailoringApp({super.key});

  @override
  _TailoringAppState createState() => _TailoringAppState();
}

class _TailoringAppState extends State<TailoringApp> {
  int _selectedIndex = 0;
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      const CustomerListPage(),
      const CustomerFormPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tailoring App'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Home Page with DateTime and Welcome Message
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    String formattedDateTime = DateFormat('MMMM dd, yyyy – hh:mm a').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Bwana Yamzy!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            'Today is $formattedDateTime',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// Model for Customer
class Customer {
  int? id;
  String name;
  String? phoneNumber;
  String kb, hflog, waist, dressLength, hip;

  Customer({
    this.id,
    required this.name,
    this.phoneNumber,
    required this.kb,
    required this.hflog,
    required this.waist,
    required this.dressLength,
    required this.hip,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'kb': kb,
      'hflog': hflog,
      'waist': waist,
      'dressLength': dressLength,
      'hip': hip,
    };
  }
}

// Database Helper for SQLite
class DatabaseHelper {
  static Future<Database> _getDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, 'tailoring.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE customers(id INTEGER PRIMARY KEY, name TEXT, phoneNumber TEXT, kb TEXT, hflog TEXT, waist TEXT, dressLength TEXT, hip TEXT)',
        );
      },
      version: 1,
    );
  }

  static Future<void> insertCustomer(Customer customer) async {
    final db = await _getDatabase();
    await db.insert('customers', customer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Customer>> fetchCustomers() async {
    final db = await _getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('customers', orderBy: 'id ASC');
    return List.generate(maps.length, (i) {
      return Customer(
        id: maps[i]['id'],
        name: maps[i]['name'],
        phoneNumber: maps[i]['phoneNumber'],
        kb: maps[i]['kb'],
        hflog: maps[i]['hflog'],
        waist: maps[i]['waist'],
        dressLength: maps[i]['dressLength'],
        hip: maps[i]['hip'],
      );
    });
  }

  static Future<void> updateCustomer(Customer customer) async {
    final db = await _getDatabase();
    await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  static Future<void> deleteCustomer(int id) async {
    final db = await _getDatabase();
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}

// Customer List Page
class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  _CustomerListPageState createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    final customers = await DatabaseHelper.fetchCustomers();
    setState(() {
      _customers = customers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _customers.length,
      itemBuilder: (context, index) {
        final customer = _customers[index];
        return ListTile(
          title: Text(customer.name),
          subtitle: Text('Phone: ${customer.phoneNumber ?? 'N/A'}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerFormPage(customer: customer),
                    ),
                  ).then((_) => _fetchCustomers()); // Refresh list after editing
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  DatabaseHelper.deleteCustomer(customer.id!);
                  _fetchCustomers();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// Customer Form Page for Add/Edit
class CustomerFormPage extends StatefulWidget {
  final Customer? customer;

  const CustomerFormPage({super.key, this.customer});

  @override
  _CustomerFormPageState createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _name, _phoneNumber, _kb, _hflog, _waist, _dressLength, _hip;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _name = widget.customer!.name;
      _phoneNumber = widget.customer!.phoneNumber;
      _kb = widget.customer!.kb;
      _hflog = widget.customer!.hflog;
      _waist = widget.customer!.waist;
      _dressLength = widget.customer!.dressLength;
      _hip = widget.customer!.hip;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            _buildTextField('Name', _name, (value) => _name = value, 'Enter name'),
            _buildTextField('Phone Number (optional)', _phoneNumber, (value) => _phoneNumber = value),
            _buildTextField('KB', _kb, (value) => _kb = value, 'Enter KB'),
            _buildTextField('HFlog', _hflog, (value) => _hflog = value, 'Enter HFlog'),
            _buildTextField('Waist', _waist, (value) => _waist = value, 'Enter Waist'),
            _buildTextField('Dress Length', _dressLength, (value) => _dressLength = value, 'Enter Dress Length'),
            _buildTextField('Hip', _hip, (value) => _hip = value, 'Enter Hip'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitForm,
              child: Text(widget.customer == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  TextFormField _buildTextField(String label, String? initialValue, Function(String) onSaved, [String? validatorText]) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(labelText: label),
      onSaved: (value) => onSaved(value!),
      validator: (value) => value!.isEmpty && validatorText != null ? validatorText : null,
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newCustomer = Customer(
        id: widget.customer?.id,
        name: _name!,
        phoneNumber: _phoneNumber,
        kb: _kb!,
        hflog: _hflog!,
        waist: _waist!,
        dressLength: _dressLength!,
        hip: _hip!,
      );

      if (widget.customer == null) {
        DatabaseHelper.insertCustomer(newCustomer);
      } else {
        DatabaseHelper.updateCustomer(newCustomer);
      }
      Navigator.pop(context, true);
    }
  }
}
