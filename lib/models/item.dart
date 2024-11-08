// lib/models/item.dart

class Item {
  String name;
  int quantity;
  bool bought;

  Item({
    required this.name,
    required this.quantity,
    required this.bought,
  });

  // Método para salvar o item no formato que será usado pelo SharedPreferences
  String toString() {
    return '$name,$quantity,$bought';
  }

  // Método para criar um Item a partir de uma string do SharedPreferences
  static Item fromString(String itemStr) {
    final parts = itemStr.split(',');
    return Item(
      name: parts[0],
      quantity: int.parse(parts[1]),
      bought: parts[2] == 'true',
    );
  }
}
