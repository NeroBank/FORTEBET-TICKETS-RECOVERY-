import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

void main() => runApp(const RecoveryApp());

const red = Color(0xFFE51D2A);
const dark = Color(0xFF101116);
const panel = Color(0xFF1B1E26);
const gold = Color(0xFFFFC928);

class RecoveryApp extends StatelessWidget {
  const RecoveryApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'FORTBET TICKET RECOVERY',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: dark,
      colorScheme: ColorScheme.fromSeed(seedColor: red, brightness: Brightness.dark),
      useMaterial3: true,
    ),
    home: const HomePage(),
  );
}

class TicketDb {
  static Database? _database;
  static Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = p.join(await getDatabasesPath(), 'fortbet_recovery.db');
    _database = await openDatabase(dbPath, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE tickets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ticket_id TEXT NOT NULL UNIQUE,
          result_status TEXT NOT NULL,
          payment_status TEXT NOT NULL,
          winnings TEXT NOT NULL,
          stake TEXT,
          odds TEXT,
          selections TEXT,
          raw_ocr TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    });
    return _database!;
  }

  static Future<List<Map<String, Object?>>> all() async =>
    (await database).query('tickets', orderBy: 'created_at DESC');

  static Future<void> save(Map<String, Object?> record) async =>
    (await database).insert('tickets', record, conflictAlgorithm: ConflictAlgorithm.abort);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  List<Map<String, Object?>> records = [];
  @override
  void initState() { super.initState(); refresh(); }
  Future<void> refresh() async {
    final rows = await TicketDb.all();
    if (mounted) setState(() => records = rows);
  }

  double get outstanding => records.where((r) =>
    r['result_status'] == 'WON' && r['payment_status'] == 'UNPAID')
    .fold(0.0, (sum, r) => sum + (double.tryParse('${r['winnings']}'.replaceAll(',', '')) ?? 0));

  @override
  Widget build(BuildContext context) {
    final pages = [
      dashboard(),
      ScanPage(onSaved: refresh),
      SearchPage(),
      history(),
    ];
    return Scaffold(
      appBar: AppBar(
        
          title: Row(
  children: [
    Image.asset(
      'assets/fortbet_logo.png',
      width: 165,
      height: 46,
      fit: BoxFit.contain,
    ),
    const SizedBox(width: 8),
    const Expanded(
      child: Text(
        'RECOVERY',
        maxLines: 1,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    ),
  ],
),
      const SizedBox(width: 8),
      const Expanded(
        child: Text(
          'RECOVERY',
          maxLines: 1,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    ],
  ),
),
        ]),
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel, selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.document_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }

  Widget dashboard() => RefreshIndicator(
    onRefresh: refresh,
    child: ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF8F101A), red]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('OUTSTANDING WINNINGS', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('₦${outstanding.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: gold)),
          Text('${records.where((r) => r['result_status'] == 'WON' && r['payment_status'] == 'UNPAID').length} unpaid winning tickets'),
        ]),
      ),
      const SizedBox(height: 18),
      const Text('Recent records', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      if (records.isEmpty)
        const Card(color: panel, child: Padding(
          padding: EdgeInsets.all(22),
          child: Text('No tickets saved yet. Use Scan to capture an individual terminal result.',
            textAlign: TextAlign.center),
        ))
      else ...records.take(8).map((r) => Card(
        color: panel,
        child: ListTile(
          title: Text('${r['ticket_id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('₦${r['winnings']} • ${r['result_status']} • ${r['payment_status']}'),
          trailing: const Icon(Icons.receipt_long),
        ),
      )),
      const SizedBox(height: 10),
      const Text('A WON result is not proof of unpaid status. Confirm payment status on the terminal.',
        style: TextStyle(color: Colors.white60, fontSize: 12)),
    ]),
  );

  Widget history() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Saved ticket history', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    if (records.isEmpty) const Text('No saved records.')
    else ...records.map((r) => Card(
      color: panel,
      child: ListTile(
        title: Text('${r['ticket_id']}'),
        subtitle: Text('Result: ${r['result_status']}  |  Payment: ${r['payment_status']}\\n₦${r['winnings']}'),
        isThreeLine: true,
      ),
    )),
  ]);
}

class ScanPage extends StatefulWidget {
  final VoidCallback onSaved;
  const ScanPage({super.key, required this.onSaved});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final picker = ImagePicker();
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool loading = false;

  @override
  void dispose() { recognizer.close(); super.dispose(); }

  Future<void> scan(ImageSource source) async {
    final photo = await picker.pickImage(source: source, imageQuality: 95);
    if (photo == null) return;
    setState(() => loading = true);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(photo.path));
      if (!mounted) return;
      setState(() => loading = false);
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => ReviewPage(
          photoPath: photo.path, rawText: result.text, onSaved: widget.onSaved,
        ),
      ));
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OCR error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Scan individual ticket', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('Photograph the terminal result with Ticket ID, winning amount, result and PAID/UNPAID status visible.',
      style: TextStyle(color: Colors.white70)),
    const SizedBox(height: 25),
    Container(
      height: 170, decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18)),
      child: const Icon(Icons.document_scanner_outlined, size: 76, color: red),
    ),
    const SizedBox(height: 20),
    FilledButton.icon(
      onPressed: loading ? null : () => scan(ImageSource.camera),
      icon: const Icon(Icons.camera_alt), label: const Text('TAKE PHOTO'),
    ),
    OutlinedButton.icon(
      onPressed: loading ? null : () => scan(ImageSource.gallery),
      icon: const Icon(Icons.photo_library), label: const Text('IMPORT PHOTO'),
    ),
    if (loading) const Center(child: Padding(
      padding: EdgeInsets.all(15), child: CircularProgressIndicator(),
    )),
    const SizedBox(height: 12),
    const Text('Review and correct every OCR field before saving. This prototype does not connect to Fortebet or retrieve secure codes.',
      style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
  ]);
}

class ReviewPage extends StatefulWidget {
  final String photoPath, rawText;
  final VoidCallback onSaved;
  const ReviewPage({super.key, required this.photoPath, required this.rawText, required this.onSaved});
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late final id = TextEditingController(text: RegExp(r'\b\d{10,20}\b').firstMatch(widget.rawText)?.group(0) ?? '');
  late final winnings = TextEditingController(text: findAmount('Win'));
  late final stake = TextEditingController(text: findAmount('Placed bet'));
  late final odds = TextEditingController(text: RegExp(r'Total\s+Odds\s*:\s*([\d.]+)', caseSensitive: false).firstMatch(widget.rawText)?.group(1) ?? '');
  late final selections = TextEditingController(text: widget.rawText.split('\n').where((s) => s.contains(' - ')).join('\\n'));
  late String result =
    widget.rawText.toUpperCase().contains('WON') ? 'WON' : 'UNKNOWN';

late String payment =
    widget.rawText.toUpperCase().contains('UNPAID')
        ? 'UNPAID'
        : (widget.rawText.toUpperCase().contains('PAID')
            ? 'PAID'
            : 'UNKNOWN');
  String findAmount(String label) {
    for (final line in widget.rawText.split('\n')) {
      if (line.toLowerCase().contains(label.toLowerCase())) {
        final m = RegExp(r'([\d,]+(?:\.\d{1,2})?)').firstMatch(line);
        if (m != null) return m.group(1)!;
      }
    }
    return '';
  }

  @override
  void dispose() { id.dispose(); winnings.dispose(); stake.dispose(); odds.dispose(); selections.dispose(); super.dispose(); }

  Widget field(String label, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: TextField(controller: c, decoration: InputDecoration(labelText: label, filled: true, fillColor: panel)),
  );

  Future<void> save() async {
    final ticketId = id.text.trim();
    if (!RegExp(r'^\d{8,20}$').hasMatch(ticketId) || winnings.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Check the Ticket ID and winning amount before saving.')));
      return;
    }
    try {
      await TicketDb.save({
        'ticket_id': ticketId, 'result_status': result, 'payment_status': payment,
        'winnings': winnings.text.trim(), 'stake': stake.text.trim(),
        'odds': odds.text.trim(), 'selections': selections.text.trim(),
        'raw_ocr': widget.rawText, 'created_at': DateTime.now().toIso8601String(),
      });
      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved locally on this phone.')));
        Navigator.pop(context);
      }
    } on DatabaseException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This Ticket ID is already saved. Search the existing record.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Review extracted details')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      ClipRRect(borderRadius: BorderRadius.circular(12),
        child: Image.file(File(widget.photoPath), height: 145, fit: BoxFit.cover)),
      const SizedBox(height: 15),
      field('Ticket ID', id),
      field('Winning amount (NGN)', winnings),
      field('Stake (NGN)', stake),
      field('Total odds', odds),
      field('Match selections', selections),
      DropdownButtonFormField<String>(
        value: result, decoration: const InputDecoration(labelText: 'Ticket result'),
        items: ['WON', 'LOST', 'UNKNOWN'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) => setState(() => result = v!),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: payment, decoration: const InputDecoration(labelText: 'Payment status'),
        items: ['UNPAID', 'PAID', 'UNKNOWN'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) => setState(() => payment = v!),
      ),
      const SizedBox(height: 18),
      FilledButton(onPressed: save, child: const Text('CONFIRM AND SAVE')),
      ExpansionTile(title: const Text('View original OCR text'),
        children: [Padding(padding: const EdgeInsets.all(12), child: SelectableText(widget.rawText))]),
    ]),
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}
class _SearchPageState extends State<SearchPage> {
  final controller = TextEditingController();
  Map<String, Object?>? found;
  Future<void> search() async {
    final rows = await (await TicketDb.database).query(
      'tickets', where: 'ticket_id = ?', whereArgs: [controller.text.trim()], limit: 1,
    );
    setState(() => found = rows.isEmpty ? null : rows.first);
  }
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Search saved ticket', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 14),
    TextField(controller: controller, keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Enter Ticket ID'),
      onSubmitted: (_) => search()),
    const SizedBox(height: 12),
    FilledButton(onPressed: search, child: const Text('SEARCH')),
    if (found != null) Card(color: panel, child: ListTile(
      title: Text('${found!['ticket_id']}'),
      subtitle: Text('₦${found!['winnings']} • ${found!['result_status']} • ${found!['payment_status']}'),
    )),
  ]);
}
