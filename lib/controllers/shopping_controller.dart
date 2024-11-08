// lib/controllers/shopping_controller.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingController {
  // Carregar os itens da lista de compras do SharedPreferences
  Future<List<Item>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedItems = prefs.getStringList('items');

    if (savedItems != null) {
      return savedItems.map((itemStr) => Item.fromString(itemStr)).toList();
    }

    return [];
  }

  // Salvar a lista de itens no SharedPreferences
  Future<void> saveItems(List<Item> items) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedItems = items.map((item) => item.toString()).toList();
    prefs.setStringList('items', savedItems);
  }

  // Adicionar um novo item à lista
  void addItem(List<Item> items, Item newItem) {
    items.add(newItem);
  }

  // Alterar o status "comprado" de um item
  void toggleBought(List<Item> items, int index) {
    items[index].bought = !items[index].bought;
  }

  // Atualizar a quantidade de um item
  void updateQuantity(List<Item> items, int index, int quantity) {
    items[index].quantity = quantity;
  }

  // Excluir um item da lista
  Future<void> removeItem(List<Item> items, int index) async {
    items.removeAt(index); // Remove o item da lista
    await saveItems(items); // Atualiza os itens no SharedPreferences
  }

  // Gerar o relatório PDF com os itens da lista
  Future<void> generatePdf(List<Item> items) async {
    final pdf = pw.Document();

    // Adicionar uma página ao PDF
    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Relatório de Lista de Compras',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            ...items.map((item) {
              return pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(item.name),
                  pw.Text(item.quantity.toString()),
                ],
              );
            }).toList(),
          ],
        );
      },
    ));

    // Salvar o PDF no arquivo ou imprimir
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Excluir todos os itens da lista no SharedPreferences
  Future<void> clearItems() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('items');  // Remove todos os itens armazenados
  }
}
