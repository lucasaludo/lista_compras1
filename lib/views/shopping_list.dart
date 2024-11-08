import 'package:flutter/material.dart';
import 'package:rive/rive.dart'; // Importando o pacote Rive
import '../controllers/shopping_controller.dart';
import '../models/item.dart';

class ShoppingList extends StatefulWidget {
  @override
  _ShoppingListState createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  List<Item> _items = [];
  final ShoppingController _controller = ShoppingController();
  TextEditingController _controllerName = TextEditingController();
  TextEditingController _controllerQuantity = TextEditingController();

  bool _isItemAdded = false; // Controle para animar o carrinho

  late RiveAnimationController _cartAnimationController; // Controlador para a animação

  @override
  void initState() {
    super.initState();

    // Inicializando o controlador da animação com o nome da animação 'checkmark_icon'
    _cartAnimationController = OneShotAnimation(
      'checkmark_icon', // Nome da animação no arquivo checkmark_icon.riv
      autoplay: false, // Inicialmente a animação não será executada
    );

    // Carregar os itens ao iniciar a tela
    _loadItems();
  }

  // Carregar os itens de compras usando o Controller
  Future<void> _loadItems() async {
    final items = await _controller.loadItems();
    setState(() {
      _items = items;
    });
  }

  // Adicionar um item à lista de compras
  void _addItem() {
    if (_controllerName.text.isNotEmpty && _controllerQuantity.text.isNotEmpty) {
      final newItem = Item(
        name: _controllerName.text,
        quantity: int.parse(_controllerQuantity.text),
        bought: false,
      );

      setState(() {
        _controller.addItem(_items, newItem);
        _isItemAdded = true; // Indicar que um item foi adicionado
      });

      _controller.saveItems(_items);
      _controllerName.clear();
      _controllerQuantity.clear();

      // Iniciar a animação do carrinho
      _startCartAnimation();
    }
  }

  // Função para iniciar a animação do carrinho
  void _startCartAnimation() {
    _cartAnimationController.isActive = true; // Ativa a animação

    // Depois de 3 segundos, desativar a animação
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _isItemAdded = false;
      });

      // Resetando a animação após 3 segundos para que possa ser ativada novamente ao adicionar um item
      _cartAnimationController.isActive = false;
    });
  }

  // Excluir um item da lista
  void _removeItem(int index) async {
    setState(() {
      _items.removeAt(index); // Remove o item da lista
    });

    // Atualiza os itens no SharedPreferences
    await _controller.saveItems(_items);
  }

  // Gerar o PDF com a lista de itens
  void _generatePdf() async {
    await _controller.generatePdf(_items);
  }

  // Alterar o status "comprado" de um item
  void _toggleBought(int index) {
    setState(() {
      _controller.toggleBought(_items, index);
    });
    _controller.saveItems(_items);
  }

  // Exibir o dialog de edição da quantidade
  void _showEditDialog(int index) {
    // Configura o campo de quantidade com o valor atual
    _controllerQuantity.text = _items[index].quantity.toString();

    // Exibe o AlertDialog para editar a quantidade do item
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Quantidade'),
          content: TextField(
            controller: _controllerQuantity,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Quantidade'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _updateQuantity(index); // Chama a função para atualizar a quantidade
                Navigator.of(context).pop(); // Fecha o dialog
              },
              child: Text('Salvar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Fecha o dialog sem salvar
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  // Atualiza a quantidade do item
  void _updateQuantity(int index) {
    // Verifica se a quantidade é válida
    int newQuantity = int.tryParse(_controllerQuantity.text) ?? 0;

    if (newQuantity > 0) {
      setState(() {
        // Atualiza a quantidade do item no índice especificado
        _items[index].quantity = newQuantity;
      });

      // Salva as alterações no SharedPreferences
      _controller.saveItems(_items);
    }

    // Limpa o campo de quantidade após a edição
    _controllerQuantity.clear();
  }

  // Excluir todos os itens da lista
  void _clearItems() {
    setState(() {
      _items.clear(); // Limpa a lista local
    });
    _controller.clearItems(); // Chama o método no controller para limpar no banco de dados ou cache
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Compras'),
        backgroundColor: Colors.blue, // Cor do app bar
      ),
      backgroundColor: Colors.white, // Cor de fundo da tela
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Campo de entrada para adicionar item
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controllerName,
                    decoration: InputDecoration(
                      labelText: 'Nome do Item',
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controllerQuantity,
                    decoration: InputDecoration(
                      labelText: 'Quantidade',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addItem,
                ),
              ],
            ),
            SizedBox(height: 16),

            // Exibir animação do carrinho se um item foi adicionado
            if (_isItemAdded)
              Container(
                height: 150,
                width: 150,
                child: RiveAnimation.asset(
                  'assets/animations/checkmark_icon.riv', // Caminho para o arquivo Rive
                  controllers: [_cartAnimationController], // Controlador da animação
                ),
              ),

            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      '${_items[index].name} - ${_items[index].quantity} unidades',
                      style: TextStyle(
                        decoration: _items[index].bought
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    leading: Checkbox(
                      value: _items[index].bought,
                      onChanged: (bool? value) {
                        _toggleBought(index);
                      },
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            _showEditDialog(index); // Exibe o dialog de edição
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _removeItem(index); // Chama a função para excluir o item
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Botão para gerar o PDF
            ElevatedButton(
              onPressed: _generatePdf,
              child: Text("Gerar Relatório PDF"),
            ),

            // Botão para excluir todos os itens da lista
            ElevatedButton(
              onPressed: _clearItems,
              child: Text("Excluir Todos os Itens"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}