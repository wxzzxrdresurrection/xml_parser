import 'package:flutter/material.dart';
import 'package:xml_parser/services/excel_creator.dart';
import 'package:xml_parser/ui/widgets/title_bar.dart';
import '../widgets/products_table.dart';
import '../../models/products.dart';
import '../../services/db.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  final List<DataColumn> columns = const [
    DataColumn(label: Text('ID')),
    DataColumn(label: Text('Descripción')),
    DataColumn(label: Text('Clave ProdServ')),
    DataColumn(label: Text('Clave Unidad')),
    DataColumn(label: Text('Cantidad')),
    DataColumn(label: Text('Valor Unitario')),
    DataColumn(label: Text('Importe')),
    DataColumn(label: Text('Fecha de Registro')),
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final loadedProducts = await DatabaseHelper.instance.getProducts();
    setState(() {
      products = loadedProducts;
      filteredProducts = loadedProducts;
      isLoading = false;
    });
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredProducts = products;
      } else {
        filteredProducts = products.where((product) {
          final searchLower = query.toLowerCase();
          return product.description.toLowerCase().contains(searchLower) ||
              product.identificationNumber.toLowerCase().contains(
                searchLower,
              ) ||
              product.unitCode.toLowerCase().contains(searchLower) ||
              product.unitName.toLowerCase().contains(searchLower);
        }).toList();
      }
    });
  }

  final currencyFormatter = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        title: TitleBar(onProductsAdded: _loadProducts),
      ),
      body: Container(
        margin: EdgeInsets.only(left: 32, right: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 300,
                  height: 35,
                  child: TextFormField(
                    controller: _searchController,
                    onChanged: _filterProducts,
                    cursorHeight: 14,
                    cursorColor: Color.fromARGB(255, 53, 95, 177),
                    decoration: InputDecoration(
                      labelText: 'Buscar producto',
                      border: OutlineInputBorder(),
                      isDense: true,
                      labelStyle: TextStyle(fontSize: 14),
                      prefixIcon: Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _filterProducts('');
                              },
                            )
                          : null,
                      focusColor: Color.fromARGB(255, 53, 95, 177),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 53, 95, 177),
                          width: 2,
                        ),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: Color.fromARGB(255, 53, 95, 177),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: FilledButton.tonalIcon(
                    onPressed: () async {

                      String? filePath = await ExcelCreator.createExcel(
                        filteredProducts,
                        columns,
                      );
                      if (filePath != null && context.mounted) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Exportación exitosa'),
                              content: Text('Archivo guardado en:\n$filePath'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('Aceptar'),
                                ),
                              ],
                            );
                          },
                        );
                      } else if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Exportación cancelada'),
                              content: Text('No se guardó el archivo.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('Aceptar'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    label: Text('Exportar a Excel'),
                    icon: Icon(Icons.file_download),
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Color.fromARGB(255, 4, 99, 21),
                      ),
                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ), // Espaciador
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : CustomPaginatedTable(
                      columns: columns,
                      rows: filteredProducts
                          .map(
                            (p) => [
                              p.id,
                              p.description,
                              p.identificationNumber,
                              p.unitCode,
                              p.quantity,
                              currencyFormatter.format(p.unitPrice),
                              currencyFormatter.format(p.totalAmount),
                              DateFormat('dd/MM/yyyy').format(p.createdAt),
                            ],
                          )
                          .toList(),
                      rowsPerPage: 10,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
