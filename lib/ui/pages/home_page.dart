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
  static const String _allProvidersValue = '__ALL__';
  String _selectedProvider = _allProvidersValue;
  List<String> _providerOptions = [];

  final List<DataColumn> columns = const [
    DataColumn(label: Text('ID')),
    DataColumn(label: Text('Proveedor')),
    DataColumn(label: Text('Descripción')),
    DataColumn(label: Text('Clave ProdServ')),
    DataColumn(label: Text('Clave Unidad')),
    DataColumn(label: Text('Cantidad')),
    DataColumn(label: Text('Valor Unitario')),
    DataColumn(label: Text('Importe')),
    DataColumn(label: Text('Fecha Emisión')),
    DataColumn(label: Text('Folio')),
    DataColumn(label: Text('UUID')),
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
    final providers = loadedProducts
        .map((p) => (p.supplierName ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    setState(() {
      products = loadedProducts;
      _providerOptions = providers;
      if (_selectedProvider != _allProvidersValue &&
          !_providerOptions.contains(_selectedProvider)) {
        _selectedProvider = _allProvidersValue;
      }
      _applyFilters();
      isLoading = false;
    });
  }

  void _filterProducts(String query) {
    setState(() {
      _applyFilters();
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final provider = _selectedProvider;

    filteredProducts = products.where((product) {
      // Filtro de proveedor
      final matchesProvider =
          provider == _allProvidersValue ||
          (product.supplierName ?? '').trim() == provider;
      if (!matchesProvider) return false;

      // Filtro de texto (SIN incluir proveedor)
      if (query.isEmpty) return true;
      return product.description.toLowerCase().contains(query) ||
          product.identificationNumber.toLowerCase().contains(query) ||
          product.unitCode.toLowerCase().contains(query) ||
          product.unitName.toLowerCase().contains(query) ||
          (product.invoiceFolio ?? '').toLowerCase().contains(query) ||
          (product.invoiceUuid ?? '').toLowerCase().contains(query);
    }).toList();
  }

  String formatDate(DateTime? value) =>
      value == null ? '-' : DateFormat('dd/MM/yyyy').format(value);

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
                  width: 240,
                  height: 35,
                  child: DropdownButtonFormField<String>(
                    value: _selectedProvider,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Proveedor',
                      border: OutlineInputBorder(),
                      isDense: true,
                      labelStyle: TextStyle(fontSize: 14),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: _allProvidersValue,
                        child: Text('Todos'),
                      ),
                      ..._providerOptions.map((provider) {
                        return DropdownMenuItem(
                          value: provider,
                          child: Text(
                            provider,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedProvider = value;
                        _applyFilters();
                      });
                    },
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
                ),
              ],
            ),
            SizedBox(height: 40),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : CustomPaginatedTable(
                      columns: columns,
                      rows: filteredProducts
                          .map(
                            (p) => [
                              p.id,
                              p.supplierName ?? '-',
                              p.description,
                              p.identificationNumber,
                              p.unitCode,
                              p.quantity,
                              currencyFormatter.format(p.unitPrice),
                              currencyFormatter.format(p.totalAmount),
                              formatDate(p.invoiceDate),
                              p.invoiceFolio ?? '-',
                              p.invoiceUuid ?? '-',
                              formatDate(p.createdAt),
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