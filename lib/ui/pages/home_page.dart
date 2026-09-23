import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:xml_parser/services/excel_creator.dart';
import 'package:xml_parser/ui/theme/app_theme.dart';
import 'package:xml_parser/ui/utils/formatters.dart';
import 'package:xml_parser/ui/widgets/empty_state.dart';
import 'package:xml_parser/ui/widgets/summary_cards.dart';
import 'package:xml_parser/ui/widgets/title_bar.dart';
import 'package:xml_parser/ui/widgets/xml_upload_dialog.dart';
import '../widgets/products_table.dart';
import '../../models/products.dart';
import '../../services/db.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Índice de la columna "Fecha Emisión" en [productColumns].
  static const int _invoiceDateColumn = 8;
  static const String _allProvidersValue = '__ALL__';

  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;
  String? _loadError;
  bool _isExporting = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _selectedProvider = _allProvidersValue;
  List<String> _providerOptions = [];

  // La base de datos ya devuelve los productos por fecha de emisión
  // descendente; la tabla lo refleja desde el inicio.
  int? _sortColumnIndex = _invoiceDateColumn;
  bool _sortAscending = false;

  bool get _hasActiveFilters =>
      _searchController.text.isNotEmpty ||
      _selectedProvider != _allProvidersValue;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final List<Product> loadedProducts;
    try {
      loadedProducts = await DatabaseHelper.instance.getProducts();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        isLoading = false;
      });
      return;
    }
    final providers =
        loadedProducts
            .map((p) => (p.supplierName ?? '').trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (!mounted) return;
    setState(() {
      products = loadedProducts;
      _providerOptions = providers;
      if (_selectedProvider != _allProvidersValue &&
          !_providerOptions.contains(_selectedProvider)) {
        _selectedProvider = _allProvidersValue;
      }
      _applyFilters();
      _loadError = null;
      isLoading = false;
    });
  }

  void _filterProducts(String _) {
    setState(() {
      _applyFilters();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedProvider = _allProvidersValue;
      _applyFilters();
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final query = _normalize(_searchController.text.trim());
    final provider = _selectedProvider;

    final filtered = products.where((product) {
      // Filtro de proveedor
      final matchesProvider =
          provider == _allProvidersValue ||
          (product.supplierName ?? '').trim() == provider;
      if (!matchesProvider) return false;

      // Filtro de texto (SIN incluir proveedor)
      if (query.isEmpty) return true;
      return [
        product.description,
        product.identificationNumber,
        product.unitCode,
        product.unitName,
        product.invoiceFolio ?? '',
        product.invoiceUuid ?? '',
      ].any((field) => _normalize(field).contains(query));
    }).toList();

    if (_sortColumnIndex != null) {
      sortProducts(filtered, _sortColumnIndex!, _sortAscending);
    }

    filteredProducts = filtered;
  }

  static const _accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };

  /// Minúsculas y sin acentos, para que "tóner" y "toner" coincidan.
  static String _normalize(String value) {
    final lower = value.toLowerCase();
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString();
  }

  Future<void> _uploadXml() {
    return pickAndUploadXml(context, onProductsAdded: _loadProducts);
  }

  Future<void> _exportToExcel() async {
    if (_isExporting || filteredProducts.isEmpty) return;
    setState(() => _isExporting = true);

    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      final filePath = await ExcelCreator.createExcel(filteredProducts);
      // Si el usuario cancela el diálogo de guardado no hace falta avisarle.
      if (filePath == null) return;

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Se exportaron ${Formatters.integer.format(filteredProducts.length)} '
                  'productos a ${p.basename(filePath)}',
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Abrir carpeta',
            textColor: Colors.white,
            onPressed: () => _revealInFileExplorer(filePath),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('No se pudo exportar el archivo: $e'),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _revealInFileExplorer(String filePath) async {
    try {
      if (Platform.isWindows) {
        await Process.start('explorer.exe', ['/select,', filePath]);
      } else if (Platform.isMacOS) {
        await Process.start('open', ['-R', filePath]);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [p.dirname(filePath)]);
      }
    } catch (_) {
      // Abrir la carpeta es solo una comodidad; si falla no interrumpimos.
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            _searchFocus.requestFocus(),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true):
            _uploadXml,
        const SingleActivator(LogicalKeyboardKey.keyE, control: true):
            _exportToExcel,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 72,
            titleSpacing: 32,
            title: TitleBar(onUploadPressed: _uploadXml),
            actions: const [SizedBox(width: 16)],
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isLoading &&
                    _loadError == null &&
                    products.isNotEmpty) ...[
                  SummaryCards(
                    products: filteredProducts,
                    totalProducts: products.length,
                  ),
                  const SizedBox(height: 20),
                  _buildToolbar(context),
                  const SizedBox(height: 16),
                ],
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Cargando productos'),
      );
    }
    if (_loadError != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'No se pudieron cargar los productos',
        message: 'Ocurrió un error al leer la base de datos. Intenta de nuevo.',
        actionLabel: 'Reintentar',
        actionIcon: Icons.refresh,
        onAction: () {
          setState(() => isLoading = true);
          _loadProducts();
        },
      );
    }
    if (products.isEmpty) {
      return EmptyState(
        icon: Icons.upload_file,
        title: 'Aún no hay productos',
        message:
            'Carga uno o varios archivos XML de facturas (CFDI) para ver '
            'aquí sus conceptos y exportarlos a Excel.',
        actionLabel: 'Cargar XML',
        actionIcon: Icons.upload_file,
        onAction: _uploadXml,
      );
    }
    if (filteredProducts.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Sin resultados',
        message:
            'Ningún producto coincide con la búsqueda o el proveedor '
            'seleccionado.',
        actionLabel: 'Limpiar filtros',
        actionIcon: Icons.filter_alt_off_outlined,
        onAction: _clearFilters,
      );
    }
    return ProductsTable(
      products: filteredProducts,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      onSort: _onSort,
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          _buildToolbarRow(context, compact: constraints.maxWidth < 1000),
    );
  }

  /// En ventanas angostas ([compact]) los campos se encogen y los botones
  /// secundarios pasan a ser solo icono, para que nada se desborde.
  Widget _buildToolbarRow(BuildContext context, {required bool compact}) {
    final count = Formatters.integer.format(filteredProducts.length);
    return Row(
      children: [
        SizedBox(
          width: compact ? 240 : 340,
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            onChanged: _filterProducts,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Buscar producto, clave, folio o UUID',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        _searchController.clear();
                        _filterProducts('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: compact ? 220 : 260,
          child: DropdownButtonFormField<String>(
            // La key fuerza a reflejar el valor cuando se limpian los filtros.
            key: ValueKey(_selectedProvider),
            initialValue: _selectedProvider,
            isExpanded: true,
            style: Theme.of(context).textTheme.bodyMedium,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.storefront_outlined, size: 20),
            ),
            items: [
              DropdownMenuItem(
                value: _allProvidersValue,
                child: Text(compact ? 'Todos' : 'Todos los proveedores'),
              ),
              ..._providerOptions.map((provider) {
                return DropdownMenuItem(
                  value: provider,
                  child: Text(provider, overflow: TextOverflow.ellipsis),
                );
              }),
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
        if (_hasActiveFilters) ...[
          const SizedBox(width: 8),
          if (compact)
            IconButton(
              onPressed: _clearFilters,
              tooltip: 'Limpiar filtros',
              icon: const Icon(Icons.filter_alt_off_outlined),
            )
          else
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Limpiar filtros'),
            ),
        ],
        const SizedBox(width: 12),
        const Spacer(),
        Tooltip(
          message: 'Exportar los productos visibles (Ctrl+E)',
          child: FilledButton.icon(
            onPressed: filteredProducts.isEmpty || _isExporting
                ? null
                : _exportToExcel,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.file_download_outlined),
            label: Text(
              _isExporting
                  ? 'Exportando…'
                  : compact
                  ? 'Exportar ($count)'
                  : 'Exportar a Excel ($count)',
            ),
          ),
        ),
      ],
    );
  }
}
