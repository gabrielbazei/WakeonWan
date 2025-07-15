import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const WakeOnWanApp());
}

class WakeOnWanApp extends StatelessWidget {
  const WakeOnWanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wake on Wan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF008B8B), // darkcyan
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008B8B),
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF006666),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          labelStyle: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF005F5F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const WakeOnWanHomePage(),
    );
  }
}

class WakeOnWanHomePage extends StatefulWidget {
  const WakeOnWanHomePage({super.key});

  @override
  State<WakeOnWanHomePage> createState() => _WakeOnWanHomePageState();
}

class _WakeOnWanHomePageState extends State<WakeOnWanHomePage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _macController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, String>> _macs = [];
  String? _savedId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedId = prefs.getString('id') ?? '';
    final macsString = prefs.getString('macs');
    print("Dados carregados - id: $loadedId, macs: $macsString");
    setState(() {
      _savedId = loadedId;
      _idController.text = loadedId;
      if (macsString != null) {
        final decoded = json.decode(macsString) as List;
        _macs = decoded.map((item) => Map<String, String>.from(item)).toList();
      }
    });
  }

  Future<void> _saveId() async {
    final prefs = await SharedPreferences.getInstance();
    final newId = _idController.text.trim();
    await prefs.setString('id', newId);
    print("ID salvo: $newId");
    setState(() {
      _savedId = newId;
    });
  }

  Future<void> _addMac() async {
    if (_macController.text.isEmpty || _nameController.text.isEmpty) return;
    final newMac = {
      'mac': _macController.text.trim(),
      'name': _nameController.text.trim(),
    };
    setState(() {
      _macs.add(newMac);
      _macController.clear();
      _nameController.clear();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('macs', json.encode(_macs));
    print("MAC salvo: $newMac");
  }

  Future<void> _confirmRemove(int index) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF006666),
        title: const Text('Confirmação', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Você tem certeza que deseja remover este MAC?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _removeMac(index);
    }
  }

  Future<void> _removeMac(int index) async {
    setState(() {
      _macs.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('macs', json.encode(_macs));
  }

  Future<void> _wakeMac(String mac) async {
    if (_savedId == null || _savedId!.isEmpty) return;
    final url = Uri.parse('https://wakeonwan-bazei.azurewebsites.net/id');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': _savedId, 'mac': mac}),
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF006666),
        content: Text(
          response.statusCode == 201
              ? 'Solicitação enviada com sucesso'
              : 'Falha ao enviar solicitação',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/wakeonwan.png', height: 100),
                const SizedBox(height: 20),
                Text(
                  'Wake on Wan',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Wake up your computer from anywhere',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'ID',
                    prefixIcon: Icon(Icons.person, color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveId,
                    child: const Text('Salvar ID'),
                  ),
                ),
                const SizedBox(height: 24),
                if (_savedId != null && _savedId!.isNotEmpty) ...[
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.computer, color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _macController,
                    decoration: const InputDecoration(
                      labelText: 'MAC Address (00:00:00:00:00:00)',
                      prefixIcon: Icon(Icons.memory, color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addMac,
                      child: const Text('Adicionar MAC'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_macs.isNotEmpty) ...[
                    const Text(
                      'MACs Salvos:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _macs.length,
                      itemBuilder: (context, index) {
                        final macObj = _macs[index];
                        return Card(
                          color: const Color(0xFF006666),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(
                              '${macObj['name']} (${macObj['mac']})',
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF005F5F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                  ),
                                  onPressed: () => _wakeMac(macObj['mac']!),
                                  child: const Text('Wake'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF004747),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                  ),
                                  onPressed: () => _confirmRemove(index),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
