// Importa os pacotes necessários para o app
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Função principal que inicia o aplicativo
void main() {
  runApp(const WakeOnWanApp());
}

// Widget principal do aplicativo
class WakeOnWanApp extends StatelessWidget {
  const WakeOnWanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wake on Wan',
      debugShowCheckedModeBanner: false,
      // Define o tema do aplicativo com cores e estilos personalizados
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(
          0xFF008B8B,
        ), // Define a cor de fundo (darkcyan)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008B8B),
          brightness: Brightness.dark,
        ),
        // Configuração dos estilos dos campos de entrada
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF006666),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          labelStyle: TextStyle(color: Colors.white),
        ),
        // Configuração do estilo dos botões elevados
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
      // Define a página inicial do aplicativo
      home: const WakeOnWanHomePage(),
    );
  }
}

// Página inicial do aplicativo (Stateful, pois possui dados mutáveis)
class WakeOnWanHomePage extends StatefulWidget {
  const WakeOnWanHomePage({super.key});

  @override
  State<WakeOnWanHomePage> createState() => _WakeOnWanHomePageState();
}

// Estado da página inicial
class _WakeOnWanHomePageState extends State<WakeOnWanHomePage> {
  // Controladores para os campos de texto (ID, MAC e Nome)
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _macController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Lista para armazenar os dispositivos salvos (cada dispositivo é um Map com 'mac' e 'name')
  List<Map<String, String>> _macs = [];

  // Variável para armazenar o ID salvo
  String? _savedId;

  // Ao iniciar o estado, carrega os dados salvos no SharedPreferences
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Carrega os dados salvos (ID e lista de MACs) do SharedPreferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    // Recupera o ID ou usa string vazia se não existir
    final loadedId = prefs.getString('id') ?? '';
    // Recupera a lista de MACs (salva em formato JSON)
    final macsString = prefs.getString('macs');
    setState(() {
      _savedId = loadedId;
      _idController.text = loadedId;
      if (macsString != null) {
        // Decodifica a string JSON para uma lista e converte cada item para Map<String, String>
        final decoded = json.decode(macsString) as List;
        _macs = decoded.map((item) => Map<String, String>.from(item)).toList();
      }
    });
  }

  // Salva o ID no SharedPreferences
  Future<void> _saveId() async {
    final prefs = await SharedPreferences.getInstance();
    final newId = _idController.text.trim();
    await prefs.setString('id', newId);
    setState(() {
      _savedId = newId;
    });
  }

  // Adiciona um novo dispositivo (MAC e nome) à lista e salva no SharedPreferences
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
  }

  // Exibe um diálogo para confirmar a remoção de um dispositivo
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
          // Botão para cancelar a remoção
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          // Botão para confirmar e remover o dispositivo
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

  // Remove um dispositivo da lista e atualiza o SharedPreferences
  Future<void> _removeMac(int index) async {
    setState(() {
      _macs.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('macs', json.encode(_macs));
  }

  // Envia uma solicitação de Wake on WAN para o servidor com o ID e o MAC especificados
  Future<void> _wakeMac(String mac) async {
    if (_savedId == null || _savedId!.isEmpty) return;
    // URL do servidor que processa a solicitação
    final url = Uri.parse('https://wakeonwan-bazei.azurewebsites.net/id');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': _savedId, 'mac': mac}),
    );
    // Exibe um diálogo informando o usuário sobre o resultado da solicitação
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

  // Constrói a interface do usuário do aplicativo
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold fornece o material necessário para os widgets do app
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            // Limita a largura máxima do conteúdo para 400 pixels
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Exibe o logo do aplicativo
                Image.asset('assets/wakeonwan.png', height: 100),
                const SizedBox(height: 20),
                // Exibe o título do aplicativo com estilo personalizado
                Text(
                  'Wake on Wan',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Exibe uma descrição do aplicativo
                const Text(
                  'Wake up your computer from anywhere',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                // Campo de entrada para o ID
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'ID',
                    prefixIcon: Icon(Icons.person, color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                // Botão para salvar o ID
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveId,
                    child: const Text('Salvar ID'),
                  ),
                ),
                const SizedBox(height: 24),
                // Se o ID estiver salvo, exibe os campos para adicionar MAC e Nome
                if (_savedId != null && _savedId!.isNotEmpty) ...[
                  // Campo para digitar um nome
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.computer, color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  // Campo para digitar o endereço MAC
                  TextField(
                    controller: _macController,
                    decoration: const InputDecoration(
                      labelText: 'MAC Address (00:00:00:00:00:00)',
                      prefixIcon: Icon(Icons.memory, color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  // Botão para adicionar o dispositivo (MAC)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addMac,
                      child: const Text('Adicionar MAC'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Se houver dispositivos salvos, exibe-os em uma lista
                  if (_macs.isNotEmpty) ...[
                    const Text(
                      'MACs Salvos:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Constrói uma ListView para exibir cada dispositivo salvo
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
                            // Exibe o nome e o endereço MAC
                            title: Text(
                              '${macObj['name']} (${macObj['mac']})',
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                // Botão para enviar o comando de Wake on WAN
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
                                // Botão para remover o dispositivo, que chama a confirmação
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
