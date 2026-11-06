
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RecoveryApp());
}

const Color brandRed = Color(0xFFE51D2A);
const Color brandOrange = Color(0xFFFF641E);
const Color appBackground = Color(0xFF0D0F14);
const Color panel = Color(0xFF1B1F29);
const Color gold = Color(0xFFFFD21F);
const String naira = '\u20A6';

class RecoveryApp extends StatelessWidget {
  const RecoveryApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ForteBet Ticket Recovery',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: appBackground,
      colorScheme: ColorScheme.fromSeed(seedColor: brandRed, brightness: Brightness.dark),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF151116), foregroundColor: Colors.white, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      useMaterial3: true,
    ),
    home: const HomePage(),
  );
}

class TicketDb {
  static Database? _database;
  static Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = p.join(await getDatabasesPath(), 'fortebet_recovery.db');
    _database = await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
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

  List<Map<String, Object?>> get unpaidRecords => records.where((r) =>
      r['result_status'] == 'WON' && r['payment_status'] == 'UNPAID').toList();

  double get outstanding => unpaidRecords.fold(0.0, (sum, r) =>
      sum + (double.tryParse('${r['winnings']}'.replaceAll(',', '')) ?? 0));

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      dashboard(),
      ScanPage(onSaved: refresh),
      const SearchPage(),
      history(),
    ];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 82,
        titleSpacing: 16,
        title: Row(children: [
          Container(
            width: 58, height: 58, padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15),
              border: Border.all(color: brandOrange, width: 1.5)),
            child: ClipRRect(borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/fortebet_football.png', fit: BoxFit.contain)),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: 'FORTE', style: TextStyle(color: brandOrange, fontWeight: FontWeight.w900)),
                TextSpan(text: 'BET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ]), maxLines: 1),
              SizedBox(height: 3),
              Text('TICKET RECOVERY', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w700)),
            ],
          )),
        ]),
      ),
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel, selectedIndex: tab,
        indicatorColor: brandRed.withValues(alpha: 0.25),
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.document_scanner_outlined), selectedIcon: Icon(Icons.document_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }

  Widget dashboard() => RefreshIndicator(
    onRefresh: refresh,
    child: ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 24), children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF970D1B), Color(0xFFEF1728)],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('OUTSTANDING WINNINGS', style: TextStyle(color: Colors.white70, fontSize: 15, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          Text('$naira${outstanding.toStringAsFixed(2)}',
            style: const TextStyle(color: gold, fontSize: 36, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text('${unpaidRecords.length} unpaid winning tickets', style: const TextStyle(color: Colors.white, fontSize: 15)),
        ]),
      ),
      const SizedBox(height: 25),
      const Text('Recent records', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      if (records.isEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18)),
          child: const Text('No tickets saved yet.\nUse Scan to capture an individual terminal result.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.5)),
        )
      else ...records.take(6).map(ticketCard),
      const SizedBox(height: 18),
      const Text('A WON result is not proof of unpaid status. Confirm payment status on the Fortebet terminal before saving.',
        style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
    ]),
  );

  Widget ticketCard(Map<String, Object?> record) {
    final isUnpaid = record['result_status'] == 'WON' && record['payment_status'] == 'UNPAID';
    return Card(color: panel, margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        leading: Icon(isUnpaid ? Icons.pending_actions : Icons.receipt_long, color: isUnpaid ? gold : Colors.white70),
        title: Text('${record['ticket_id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$naira${record['winnings']}  •  ${record['result_status']}  •  ${record['payment_status']}'),
      ));
  }

  Widget history() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Saved ticket history', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    if (records.isEmpty) const Text('No saved records.')
    else ...records.map((record) => Card(color: panel, child: ListTile(
      leading: const Icon(Icons.receipt_long, color: brandOrange),
      title: Text('${record['ticket_id']}'),
      subtitle: Text('Result: ${record['result_status']}  |  Payment: ${record['payment_status']}\n$naira${record['winnings']}'),
      isThreeLine: true,
    ))),
  ]);
}

class ScanPage extends StatefulWidget {
  final VoidCallback onSaved;
  const ScanPage({super.key, required this.onSaved});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ImagePicker picker = ImagePicker();
  final TextRecognizer recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool loading = false;
  @override
  void dispose() { recognizer.close(); super.dispose(); }

  Future<void> scan(ImageSource source) async {
    final photo = await picker.pickImage(source: source, imageQuality: 95);
    if (photo == null || !mounted) return;
    setState(() => loading = true);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(photo.path));
      if (!mounted) return;
      setState(() => loading = false);
      await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ReviewPage(
        photoPath: photo.path, rawText: result.text, onSaved: widget.onSaved)));
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not read this image: $error')));
    }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Scan individual ticket', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('Photograph the terminal result with Ticket ID, winning amount, result and PAID/UNPAID status visible.',
      style: TextStyle(color: Colors.white70, height: 1.5)),
    const SizedBox(height: 24),
    Container(height: 170, decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: brandRed.withValues(alpha: 0.35))),
      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.sports_soccer, size: 64, color: brandOrange),
        SizedBox(height: 8), Text('FORTEBET TICKET CAPTURE'),
      ])),
    const SizedBox(height: 20),
    FilledButton.icon(onPressed: loading ? null : () => scan(ImageSource.camera),
      icon: const Icon(Icons.camera_alt), label: const Text('TAKE PHOTO'),
      style: FilledButton.styleFrom(backgroundColor: brandRed)),
    OutlinedButton.icon(onPressed: loading ? null : () => scan(ImageSource.gallery),
      icon: const Icon(Icons.photo_library), label: const Text('IMPORT PHOTO')),
    if (loading) const Padding(padding: EdgeInsets.all(18), child: Center(child: CircularProgressIndicator())),
    const SizedBox(height: 12),
    const Text('Review and correct every OCR field before saving. This app does not connect to Fortebet or retrieve secure codes.',
      style: TextStyle(color: Colors.orangeAccent, fontSize: 12, height: 1.5)),
  ]);
}

class ReviewPage extends StatefulWidget {
  final String photoPath;
  final String rawText;
  final VoidCallback onSaved;
  const ReviewPage({super.key, required this.photoPath, required this.rawText, required this.onSaved});
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late final TextEditingController id = TextEditingController(
    text: RegExp(r'\b\d{8,20}\b').firstMatch(widget.rawText)?.group(0) ?? '');
  late final TextEditingController winnings = TextEditingController(text: findAmount(['winning amount', 'win']));
  late final TextEditingController stake = TextEditingController(text: findAmount(['stake', 'placed bet']));
  late final TextEditingController odds = TextEditingController(
    text: RegExp(r'Total\s+Odds\s*:?\s*([\d.]+)', caseSensitive: false).firstMatch(widget.rawText)?.group(1) ?? '');
  late final TextEditingController selections = TextEditingController(
    text: widget.rawText.split('\n').where((line) => line.trim().isNotEmpty).join('\n'));
  late String resultStatus = detectResult(widget.rawText);
  late String paymentStatus = detectPayment(widget.rawText);

  String findAmount(List<String> labels) {
    for (final line in widget.rawText.split('\n')) {
      if (labels.any(line.toLowerCase().contains)) {
        final match = RegExp(r'([\d,]+(?:\.\d{1,2})?)').firstMatch(line);
        if (match != null) return match.group(1)!;
      }
    }
    return '';
  }

  String detectResult(String text) {
    final upper = text.toUpperCase();
    if (RegExp(r'\bWON\b').hasMatch(upper)) return 'WON';
    if (RegExp(r'\bLOST\b').hasMatch(upper)) return 'LOST';
    return 'UNKNOWN';
  }

  String detectPayment(String text) {
    final upper = text.toUpperCase();
    if (RegExp(r'\bUNPAID\b').hasMatch(upper)) return 'UNPAID';
    if (RegExp(r'\bPAID\b').hasMatch(upper)) return 'PAID';
    return 'UNKNOWN';
  }

  @override
  void dispose() {
    id.dispose(); winnings.dispose(); stake.dispose(); odds.dispose(); selections.dispose();
    super.dispose();
  }

  Widget field(String label, TextEditingController controller, {TextInputType? keyboardType, int maxLines = 1}) =>
    Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(
      controller: controller, keyboardType: keyboardType, maxLines: maxLines,
      decoration: InputDecoration(labelText: label)));

  Future<void> save() async {
    final ticketId = id.text.trim();
    final amount = winnings.text.trim().replaceAll(',', '');
    if (!RegExp(r'^\d{8,20}$').hasMatch(ticketId) || double.tryParse(amount) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid Ticket ID and winning amount.')));
      return;
    }
    try {
      await TicketDb.save({
        'ticket_id': ticketId, 'result_status': resultStatus, 'payment_status': paymentStatus,
        'winnings': amount, 'stake': stake.text.trim(), 'odds': odds.text.trim(),
        'selections': selections.text.trim(), 'raw_ocr': widget.rawText,
        'created_at': DateTime.now().toIso8601String(),
      });
      widget.onSaved();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket saved on this phone.')));
      Navigator.pop(context);
    } on DatabaseException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This Ticket ID is already saved. Search its record.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Review ticket details')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      ClipRRect(borderRadius: BorderRadius.circular(12),
        child: Image.file(File(widget.photoPath), height: 155, fit: BoxFit.contain)),
      const SizedBox(height: 16),
      field('Ticket ID', id, keyboardType: TextInputType.number),
      field('Winning amount (NGN)', winnings, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
      field('Stake (NGN)', stake, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
      field('Total odds', odds),
      field('Ticket text / selections', selections, maxLines: 5),
      DropdownButtonFormField<String>(
        value: resultStatus, decoration: const InputDecoration(labelText: 'Ticket result'),
        items: const ['WON', 'LOST', 'UNKNOWN'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) { if (v != null) setState(() => resultStatus = v); }),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: paymentStatus, decoration: const InputDecoration(labelText: 'Payment status'),
        items: const ['UNPAID', 'PAID', 'UNKNOWN'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) { if (v != null) setState(() => paymentStatus = v); }),
      const SizedBox(height: 18),
      FilledButton(onPressed: save, style: FilledButton.styleFrom(backgroundColor: brandRed),
        child: const Text('CONFIRM AND SAVE')),
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
  final TextEditingController controller = TextEditingController();
  Map<String, Object?>? found;
  bool searched = false;

  Future<void> search() async {
    final ticketId = controller.text.trim();
    if (ticketId.isEmpty) return;
    final rows = await (await TicketDb.database).query('tickets',
      where: 'ticket_id = ?', whereArgs: [ticketId], limit: 1);
    if (!mounted) return;
    setState(() { searched = true; found = rows.isEmpty ? null : rows.first; });
  }

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Search saved ticket', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 14),
    TextField(controller: controller, keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Enter Ticket ID', prefixIcon: Icon(Icons.confirmation_number_outlined)),
      onSubmitted: (_) => search()),
    const SizedBox(height: 12),
    FilledButton(onPressed: search, style: FilledButton.styleFrom(backgroundColor: brandRed), child: const Text('SEARCH')),
    if (searched && found == null) const Padding(padding: EdgeInsets.only(top: 18), child: Text('No saved ticket found with that ID.')),
    if (found != null) Card(color: panel, child: ListTile(
      title: Text('${found!['ticket_id']}'),
      subtitle: Text('$naira${found!['winnings']}  •  ${found!['result_status']}  •  ${found!['payment_status']}'),
    )),
  ]);
}
