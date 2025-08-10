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
//um app StatelessWidget é usado aqui porque não possui estado mutável, não precisa de gerenciamento de estado dinâmico
//e um StatefulWidget seria desnecessário
class WakeOnWanApp extends StatelessWidget {
  const WakeOnWanApp({super.key});

  @override
  // Método build que constrói a interface do usuário do aplicativo
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
// divido em um StatefulWidget para gerenciar o estado dos campos de entrada e da lista de dispositivos
// assim deixando o app mais dinâmico e responsivo às ações do usuário
class WakeOnWanHomePage extends StatefulWidget {
  const WakeOnWanHomePage({super.key});

  @override
  // Cria o estado associado a esta página, o estado é onde a lógica de manipulação de dados e eventos acontece
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
  //shared_preferences é usado para persistir dados simples entre sessões do aplicativo
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Carrega os dados salvos (ID e lista de MACs) do SharedPreferences
  Future<void> _loadData() async {
    // Obtém a instância do SharedPreferences, buscando informações persistentes
    // SharedPreferences é uma maneira de armazenar dados simples, como strings, listas e números
    final prefs = await SharedPreferences.getInstance();
    // Recupera o ID ou usa string vazia se não existir
    final loadedId = prefs.getString('id') ?? '';
    // Recupera a lista de MACs (salva em formato JSON)
    final macsString = prefs.getString('macs');
    // Atualiza o estado do widget com os dados carregados
    setState(() {
      _savedId = loadedId;
      _idController.text = loadedId;
      // Se a string de MACs não for nula, decodifica e converte para uma lista de Map<String, String>
      if (macsString != null) {
        // Decodifica a string JSON para uma lista e converte cada item para Map<String, String>
        // é necesasrio usar json.decode para converter a string JSON em uma lista de mapas
        // e Map<String, String>.from para garantir que cada item seja do tipo Map<String, String>
        // isso é necessário porque SharedPreferences armazena listas como strings JSON
        final decoded = json.decode(macsString) as List;
        // Converte a lista decodificada para uma lista de Map<String, String>
        // e atribui à variável _macs
        _macs = decoded.map((item) => Map<String, String>.from(item)).toList();
      }
    });
  }

  // Salva o ID no SharedPreferences
  Future<void> _saveId() async {
    // Pega a instância do SharedPreferences
    // e salva o ID digitado pelo usuário
    final prefs = await SharedPreferences.getInstance();
    final newId = _idController.text.trim();
    //o setString salva o ID no SharedPreferences
    await prefs.setString('id', newId);
    // Atualiza o estado do widget com o novo ID
    setState(() {
      _savedId = newId;
    });
  }

  // Adiciona um novo dispositivo (MAC e nome) à lista e salva no SharedPreferences
  Future<void> _addMac() async {
    // valida se os campos de MAC e Nome não estão vazios
    if (_macController.text.isEmpty || _nameController.text.isEmpty) return;
    // O uso de final é para garantir que a variável não seja alterada depois de definida e também melhora a velocidade do código
    // Isto é devido ao fato de que o Dart é uma linguagem de tipagem estática, e o uso de final ajuda a otimizar o desempenho
    // A tipagem estática permite que o compilador faça otimizações em tempo de compilação, melhorando a velocidade de execução do código
    final newMac = {
      // o uso de .trim() remove espaços em branco no início e no final das strings
      // e garante que os dados sejam armazenados corretamente
      'mac': _macController.text.trim(),
      'name': _nameController.text.trim(),
    };
    // Adiciona o novo dispositivo à lista de MACs
    // e atualiza o estado do widget para refletir a mudança na interface do usuário
    setState(() {
      _macs.add(newMac);
      _macController.clear();
      _nameController.clear();
    });
    // Salva a lista atualizada de MACs no SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    // converte a lista de Map<String, String> para uma string JSON usando json.encode
    await prefs.setString('macs', json.encode(_macs));
  }

  // Exibe um diálogo para confirmar a remoção de um dispositivo
  Future<void> _confirmRemove(int index) async {
    // Exibe um diálogo de confirmação antes de remover o dispositivo
    // o showDialog retorna um Future<bool> que indica se o usuário confirmou ou não a remoção
    // O uso de await permite que o código aguarde a resposta do diálogo antes de continuar
    final bool? confirmed = await showDialog<bool>(
      // o uso de context é necessário para exibir o diálogo na árvore de widgets
      context: context,
      // o builder é uma função que constrói o diálogo, permitindo personalizar sua aparência e comportamento
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
    // Se o usuário confirmou a remoção, chama o método _removeMac para remover o dispositivo
    if (confirmed == true) {
      _removeMac(index);
    }
  }

  // Remove um dispositivo da lista e atualiza o SharedPreferences
  Future<void> _removeMac(int index) async {
    // Atualiza o estado do widget para remover o dispositivo da lista
    // e chama setState para notificar o Flutter que o estado mudou
    setState(() {
      _macs.removeAt(index);
    });
    // Salva a lista atualizada de MACs no SharedPreferences
    // o uso de await garante que a operação de salvamento seja concluída antes de continuar
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('macs', json.encode(_macs));
  }

  // Envia uma solicitação de Wake on WAN para o servidor com o ID e o MAC especificados
  // Este método é responsável por enviar o comando de Wake on WAN para o servidor
  // Aqui que a magica acontece, onde o aplicativo se comunica com o servidor para acordar o computador
  Future<void> _wakeMac(String mac) async {
    // Verifica se o ID está salvo, se não estiver, não faz nada
    // Isso é importante para evitar erros ao tentar enviar uma solicitação sem um ID válido
    if (_savedId == null || _savedId!.isEmpty) return;
    // URL do servidor que processa a solicitação
    final url = Uri.parse('https://wakeonwan-bazei.azurewebsites.net/id');
    // Envia uma solicitação POST para o servidor com o ID e o MAC
    final response = await http.post(
      url,
      // Define o cabeçalho da solicitação como JSON
      headers: {'Content-Type': 'application/json'},
      // O corpo da solicitação contém o ID e o MAC em formato JSON
      body: json.encode({'id': _savedId, 'mac': mac}),
    );
    // Exibe um diálogo informando o usuário sobre o resultado da solicitação
    // Este diálogo se mostrou importante como uma forma de feedback para o usuário
    // pois permite que o usuário saiba se a solicitação foi bem-sucedida ou não
    // No website após o usuario clicar no botão "wake", ele não tinha nenhum feedback
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF006666),
        content: Text(
          // O codigo 201 indica sucesso, enquanto outros códigos indicam falha
          response.statusCode == 201
              ? 'Solicitação enviada com sucesso'
              : 'Falha ao enviar solicitação',
          style: const TextStyle(color: Colors.white),
        ),
        // Um botão para fechar o diálogo, o uso de .pop(context) fecha o diálogo
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
  // O método build é chamado sempre que o estado do widget muda, permitindo que a interface seja atualizada dinamicamente
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold fornece o material necessário para os widgets do app
      body: Center(
        // o singleChildScrollView permite que o conteúdo seja rolável
        child: SingleChildScrollView(
          child: Container(
            // Limita a largura máxima do conteúdo para 400 pixels
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            // o child e children são usados para definir o layout do conteúdo dentro do Container
            // child permite que um único widget seja colocado dentro do Container
            // children permite que uma lista de widgets seja colocada dentro do Container
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
                    //prefixIcon é usado para adicionar um ícone antes do texto do campo
                    prefixIcon: Icon(Icons.person, color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                // Botão para salvar o ID
                SizedBox(
                  // O uso de double.infinity permite que o botão ocupe toda a largura disponível
                  // Isso é útil para garantir que o botão seja responsivo e se ajuste ao tamanho da tela
                  width: double.infinity,
                  child: ElevatedButton(
                    // Aqui chama a função _saveId quando o botão é pressionado
                    onPressed: _saveId,
                    child: const Text('Salvar ID'),
                  ),
                ),
                const SizedBox(height: 24),
                // Se o ID estiver salvo, exibe os campos para adicionar MAC e Nome
                // caso o ID não esteja salvo, não exibe os campos de MAC e Nome
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
                  // O campo não força o usuário a digitar um formato específico, mas espera-se que seja no formato XX:XX:XX:XX:XX:XX
                  // isto é devido ao fato que dependendo do sistema operacional, o formato pode variar
                  // um exemplo é o linux que usa o formato XX:XX:XX:XX:XX:XX
                  // enquanto o windows usa o formato XX-XX-XX-XX-XX-XX
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
                      // Chama a função _addMac quando o botão é pressionado
                      onPressed: _addMac,
                      child: const Text('Adicionar MAC'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Se houver dispositivos salvos, exibe-os em uma lista
                  // Caso não tenha dispositivos salvos, não exibe nada
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
                    // ListView.builder é usado para criar uma lista de itens de forma eficiente
                    // O uso de shrinkWrap: true permite que a lista ocupe apenas o espaço necessário
                    ListView.builder(
                      shrinkWrap: true,
                      // O uso de physics: NeverScrollableScrollPhysics() desativa a rolagem da lista
                      // Isso é útil quando a lista está dentro de um SingleChildScrollView
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _macs.length,
                      itemBuilder: (context, index) {
                        // Obtém o objeto MAC correspondente ao índice atual
                        final macObj = _macs[index];
                        return Card(
                          color: const Color(0xFF006666),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            // Exibe o nome e o endereço MAC
                            // O uso de macObj['name'] e macObj['mac'] permite acessar os valores do Map
                            // e exibi-los na interface do usuário
                            title: Text(
                              '${macObj['name']} (${macObj['mac']})',
                              style: const TextStyle(color: Colors.white),
                            ),
                            //trailing é usado para adicionar widgets no final do ListTile
                            // Neste caso, adiciona dois botões: um para enviar o comando de Wake on WAN
                            // e outro para remover o dispositivo da lista
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
                                  //chama a função _wakeMac com o endereço MAC do dispositivo
                                  //passando o endereço MAC do dispositivo para acordar
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
                                  // Chama a função _confirmRemove para confirmar a remoção
                                  // passando o índice do dispositivo na lista
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
