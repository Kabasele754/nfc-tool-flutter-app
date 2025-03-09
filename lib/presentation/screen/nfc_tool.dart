import 'package:app_nfc_tool/data/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:ndef/record.dart';
import 'package:ndef/records/well_known/text.dart' as ndef;

class NFCTool extends StatefulWidget {
  @override
  _NFCToolState createState() => _NFCToolState();
}

class _NFCToolState extends State<NFCTool> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String nfcData = "Approche ton téléphone d'un tag NFC...";
  bool isScanning = false;
  TextEditingController textController = TextEditingController();
  List<Map<String, dynamic>> scanHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    loadHistory();
  }

  Future<void> loadHistory() async {
    final history = await DatabaseHelper().getScans();
    setState(() {
      scanHistory = history;
    });
  }

  Future<void> readNFC() async {
    setState(() => isScanning = true);
    try {
      var tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 10));

      if (tag.ndefAvailable ?? false) {
        var records = await FlutterNfcKit.readNDEFRecords();
        if (records.isNotEmpty) {
          String data = records.first.payload as String;
          setState(() => nfcData = "📡 Donnée lue : $data");
          await DatabaseHelper().saveScan(data);
          loadHistory();
        } else {
          setState(() => nfcData = "⚠️ Aucune donnée trouvée.");
        }
      } else {
        setState(() => nfcData = "⛔ Tag NFC vide ou incompatible.");
      }
      await FlutterNfcKit.finish();
    } catch (e) {
      setState(() => nfcData = "❌ Erreur: $e");
    } finally {
      setState(() => isScanning = false);
    }
  }

  Future<void> writeNFC() async {
    String message = textController.text;
    if (message.isEmpty) return;

    try {
      await FlutterNfcKit.poll(timeout: Duration(seconds: 10));
      var record = ndef.TextRecord(text: message);
      await FlutterNfcKit.writeNDEFRecords([record]);
      await FlutterNfcKit.finish();
      print("✅ Écriture réussie : $message");
    } catch (e) {
      print("❌ Erreur: $e");
    }
  }

  Future<void> clearNFC() async {
    setState(() => isScanning = true);
    try {
      await FlutterNfcKit.poll(timeout: Duration(seconds: 10));
      await FlutterNfcKit.writeNDEFRecords([]);
      await FlutterNfcKit.finish();
      setState(() => nfcData = "✅ Données NFC supprimées.");
    } catch (e) {
      setState(() => nfcData = "❌ Erreur: $e");
    } finally {
      setState(() => isScanning = false);
    }
  }

  Widget _buildScanTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          isScanning
              ? 'assets/annimation/nfc_scan.json'
              : 'assets/annimation/nfc_idle.json',
          height: 150,
        ),
        SizedBox(height: 20),
        Text(
          nfcData,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 30),
        ElevatedButton.icon(
          icon: Icon(Icons.nfc),
          label: Text("Scanner un tag NFC"),
          onPressed: readNFC,
          style: _buttonStyle(Colors.blueAccent),
        ),
      ],
    );
  }

  Widget _buildWriteTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset('assets/nfc_write.json', height: 150),
        SizedBox(height: 20),
        TextField(
          controller: textController,
          decoration: InputDecoration(
            labelText: "Texte à enregistrer",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          icon: Icon(Icons.save),
          label: Text("Écrire sur le tag NFC"),
          onPressed: writeNFC,
          style: _buttonStyle(Colors.green),
        ),
      ],
    );
  }

  Widget _buildDeleteTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset('assets/nfc_delete.json', height: 150),
        SizedBox(height: 20),
        ElevatedButton.icon(
          icon: Icon(Icons.delete),
          label: Text("Effacer le tag NFC"),
          onPressed: clearNFC,
          style: _buttonStyle(Colors.red),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: scanHistory.length,
            itemBuilder: (context, index) {
              String data = scanHistory[index]['data'];
              return Card(
                child: ListTile(
                  title: Text(data),
                  subtitle: Text(scanHistory[index]['date']),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await DatabaseHelper().deleteScan(
                        scanHistory[index]['id'],
                      );
                      loadHistory();
                    },
                  ),
                ),
              );
            },
          ),
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.delete_sweep),
          label: Text("Vider l'historique"),
          onPressed: () async {
            await DatabaseHelper().clearHistory();
            loadHistory();
          },
          style: _buttonStyle(Colors.orange),
        ),
      ],
    );
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.blueGrey[900],
        appBar: AppBar(
          title: Text(
            "NFC Tool",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(icon: Icon(Icons.nfc), text: "Scanner"),
              Tab(icon: Icon(Icons.edit), text: "Écrire"),
              Tab(icon: Icon(Icons.delete), text: "Supprimer"),
              Tab(icon: Icon(Icons.history), text: "Historique"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildScanTab(),
            _buildWriteTab(),
            _buildDeleteTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }
}
