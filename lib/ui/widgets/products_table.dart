import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xml_parser/models/products.dart';
import 'package:xml_parser/ui/utils/formatters.dart';

/// Definición de una columna de la tabla de productos.
///
/// Centraliza en un solo lugar el título, el ancho, la alineación, cómo se
/// muestra el valor y cómo se ordena.
class ProductColumn {
  final String label;
  final double width;
  final bool numeric;
  final bool monospace;

  /// Qué proporción del espacio sobrante recibe la columna cuando la ventana
  /// es más ancha que la suma de los anchos base.
  final double flex;
  final String Function(Product p) display;
  final Comparable<dynamic>? Function(Product p) sortValue;

  const ProductColumn({
    required this.label,
    required this.width,
    required this.display,
    required this.sortValue,
    this.numeric = false,
    this.monospace = false,
    this.flex = 0,
  });
}

String _orDash(String? value) =>
    (value == null || value.trim().isEmpty) ? '-' : value;

String? _lower(String? value) => value?.toLowerCase();

final List<ProductColumn> productColumns = [
  ProductColumn(
    label: 'ID',
    width: 56,
    numeric: true,
    display: (p) => '${p.id ?? '-'}',
    sortValue: (p) => p.id,
  ),
  ProductColumn(
    label: 'Proveedor',
    width: 180,
    flex: 0.35,
    display: (p) => _orDash(p.supplierName),
    sortValue: (p) => _lower(p.supplierName),
  ),
  ProductColumn(
    label: 'Descripción',
    width: 240,
    flex: 0.65,
    display: (p) => _orDash(p.description),
    sortValue: (p) => _lower(p.description),
  ),
  ProductColumn(
    label: 'Clave ProdServ',
    width: 100,
    display: (p) => _orDash(p.identificationNumber),
    sortValue: (p) => p.identificationNumber,
  ),
  ProductColumn(
    label: 'Clave Unidad',
    width: 80,
    display: (p) => _orDash(p.unitCode),
    sortValue: (p) => p.unitCode,
  ),
  ProductColumn(
    label: 'Cantidad',
    width: 90,
    numeric: true,
    display: (p) => Formatters.quantity.format(p.quantity),
    sortValue: (p) => p.quantity,
  ),
  ProductColumn(
    label: 'Valor Unitario',
    width: 120,
    numeric: true,
    display: (p) => Formatters.currency.format(p.unitPrice),
    sortValue: (p) => p.unitPrice,
  ),
  ProductColumn(
    label: 'Importe',
    width: 120,
    numeric: true,
    display: (p) => Formatters.currency.format(p.totalAmount),
    sortValue: (p) => p.totalAmount,
  ),
  ProductColumn(
    label: 'Fecha Emisión',
    width: 110,
    display: (p) => Formatters.date(p.invoiceDate),
    sortValue: (p) => p.invoiceDate,
  ),
  ProductColumn(
    label: 'Folio',
    width: 110,
    display: (p) => _orDash(p.invoiceFolio),
    sortValue: (p) => _lower(p.invoiceFolio),
  ),
  ProductColumn(
    label: 'UUID',
    width: 290,
    monospace: true,
    display: (p) => _orDash(p.invoiceUuid),
    sortValue: (p) => _lower(p.invoiceUuid),
  ),
  ProductColumn(
    label: 'Fecha de Registro',
    width: 120,
    display: (p) => Formatters.date(p.createdAt),
    sortValue: (p) => p.createdAt,
  ),
];

/// Ordena [products] en su lugar según la columna indicada.
/// Los valores vacíos siempre quedan al final, sin importar la dirección.
void sortProducts(List<Product> products, int columnIndex, bool ascending) {
  final column = productColumns[columnIndex];
  products.sort((a, b) {
    final av = column.sortValue(a);
    final bv = column.sortValue(b);
    if (av == null && bv == null) return 0;
    if (av == null) return 1;
    if (bv == null) return -1;
    final comparison = av.compareTo(bv);
    if (comparison != 0) return ascending ? comparison : -comparison;
    // List.sort no es estable: desempatar por id para que las filas con el
    // mismo valor (p. ej. conceptos de la misma factura) no cambien de orden.
    return (a.id ?? 0).compareTo(b.id ?? 0);
  });
}

class ProductsTable extends StatefulWidget {
  final List<Product> products;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending) onSort;
  final int initialRowsPerPage;

  const ProductsTable({
    super.key,
    required this.products,
    required this.onSort,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.initialRowsPerPage = 25,
  });

  static const List<int> rowsPerPageOptions = [10, 25, 50, 100];

  @override
  State<ProductsTable> createState() => _ProductsTableState();
}

class _ProductsTableState extends State<ProductsTable> {
  static const double _cellHPadding = 12;

  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();

  int _currentPage = 0;
  late int _rowsPerPage = widget.initialRowsPerPage;

  int get _totalPages =>
      math.max(1, (widget.products.length / _rowsPerPage).ceil());

  @override
  void didUpdateWidget(ProductsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Una lista nueva significa que cambió el filtro o el orden: volver al
    // inicio para no quedar en una página que ya no existe.
    if (!identical(oldWidget.products, widget.products)) {
      _currentPage = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTop());
    }
  }

  void _scrollToTop() {
    if (_verticalController.hasClients) {
      _verticalController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(0, _totalPages - 1);
    });
    _scrollToTop();
  }

  /// Anchos finales de cada columna: si sobra espacio, se reparte entre las
  /// columnas flexibles (Proveedor y Descripción).
  List<double> _columnWidths(double available) {
    final base = productColumns.fold<double>(
      0,
      (sum, c) => sum + c.width + _cellHPadding * 2,
    );
    final extra = math.max(0.0, available - base);
    return [for (final c in productColumns) c.width + extra * c.flex];
  }

  @override
  Widget build(BuildContext context) {
    final start = _currentPage * _rowsPerPage;
    final end = math.min(start + _rowsPerPage, widget.products.length);
    final pageRows = widget.products.sublist(
      math.min(start, widget.products.length),
      end,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final widths = _columnWidths(constraints.maxWidth);
                final tableWidth = widths.fold<double>(
                  0,
                  (sum, w) => sum + w + _cellHPadding * 2,
                );

                return Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: tableWidth > constraints.maxWidth,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: math.max(tableWidth, constraints.maxWidth),
                      child: Column(
                        children: [
                          _HeaderRow(
                            widths: widths,
                            sortColumnIndex: widget.sortColumnIndex,
                            sortAscending: widget.sortAscending,
                            onSort: widget.onSort,
                          ),
                          const Divider(),
                          Expanded(
                            // Un solo SelectionArea permite seleccionar y
                            // copiar texto (p. ej. un UUID) sin que cada celda
                            // sea una parada de Tab.
                            child: SelectionArea(
                              child: Scrollbar(
                                controller: _verticalController,
                                thumbVisibility: true,
                                child: ListView.separated(
                                  controller: _verticalController,
                                  itemCount: pageRows.length,
                                  separatorBuilder: (_, _) => const Divider(),
                                  itemBuilder: (context, index) => _DataRow(
                                    product: pageRows[index],
                                    widths: widths,
                                    striped: index.isOdd,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          _PaginationBar(
            start: widget.products.isEmpty ? 0 : start + 1,
            end: end,
            total: widget.products.length,
            currentPage: _currentPage,
            totalPages: _totalPages,
            rowsPerPage: _rowsPerPage,
            onRowsPerPageChanged: (value) {
              _rowsPerPage = value;
              _goToPage(0);
            },
            onPageChanged: _goToPage,
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final List<double> widths;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending) onSort;

  const _HeaderRow({
    required this.widths,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );

    return Container(
      color: scheme.surfaceContainerHigh,
      child: Row(
        children: [
          for (var i = 0; i < productColumns.length; i++)
            _HeaderCell(
              column: productColumns[i],
              width: widths[i],
              textStyle: textStyle,
              isSorted: sortColumnIndex == i,
              ascending: sortAscending,
              onTap: () => onSort(
                i,
                // Primer clic: ascendente. Clics siguientes alternan.
                sortColumnIndex == i ? !sortAscending : true,
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final ProductColumn column;
  final double width;
  final TextStyle? textStyle;
  final bool isSorted;
  final bool ascending;
  final VoidCallback onTap;

  const _HeaderCell({
    required this.column,
    required this.width,
    required this.textStyle,
    required this.isSorted,
    required this.ascending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = Icon(
      isSorted
          ? (ascending ? Icons.arrow_upward : Icons.arrow_downward)
          : Icons.unfold_more,
      size: 16,
      color: isSorted ? scheme.primary : scheme.outline,
    );
    final label = Flexible(
      child: Text(
        column.label,
        style: isSorted
            ? textStyle?.copyWith(color: scheme.primary)
            : textStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: column.numeric ? TextAlign.right : TextAlign.left,
      ),
    );

    final direction = ascending ? 'ascendente' : 'descendente';
    return Semantics(
      button: true,
      label: isSorted
          ? '${column.label}, ordenado $direction'
          : '${column.label}, sin ordenar',
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: 'Ordenar por ${column.label.toLowerCase()}',
        excludeFromSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: width + _ProductsTableState._cellHPadding * 2,
            height: 52,
            padding: const EdgeInsets.symmetric(
              horizontal: _ProductsTableState._cellHPadding,
            ),
            alignment: column.numeric
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: column.numeric
                  ? [icon, const SizedBox(width: 4), label]
                  : [label, const SizedBox(width: 4), icon],
            ),
          ),
        ),
      ),
    );
  }
}

class _DataRow extends StatefulWidget {
  final Product product;
  final List<double> widths;
  final bool striped;

  const _DataRow({
    required this.product,
    required this.widths,
    required this.striped,
  });

  @override
  State<_DataRow> createState() => _DataRowState();
}

class _DataRowState extends State<_DataRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(fontSize: 13);

    final Color background;
    if (_hovered) {
      background = scheme.primary.withValues(alpha: 0.06);
    } else if (widget.striped) {
      background = scheme.onSurface.withValues(alpha: 0.025);
    } else {
      background = Colors.transparent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        color: background,
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < productColumns.length; i++)
              Container(
                width: widget.widths[i] + _ProductsTableState._cellHPadding * 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: _ProductsTableState._cellHPadding,
                  vertical: 10,
                ),
                child: Text(
                  productColumns[i].display(widget.product),
                  textAlign: productColumns[i].numeric
                      ? TextAlign.right
                      : TextAlign.left,
                  style: productColumns[i].numeric
                      ? baseStyle?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )
                      : productColumns[i].monospace
                      ? baseStyle?.copyWith(
                          fontFamily: 'monospace',
                          fontFamilyFallback: const ['Consolas', 'Courier New'],
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        )
                      : baseStyle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int start;
  final int end;
  final int total;
  final int currentPage;
  final int totalPages;
  final int rowsPerPage;
  final ValueChanged<int> onRowsPerPageChanged;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.start,
    required this.end,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.onRowsPerPageChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final canGoBack = currentPage > 0;
    final canGoForward = currentPage < totalPages - 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        // En ventanas angostas se ocultan la etiqueta y los saltos a
        // primera/última página para que la barra no se desborde.
        final compact = constraints.maxWidth < 760;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Flexible(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    'Mostrando ${Formatters.integer.format(start)}–'
                    '${Formatters.integer.format(end)} de '
                    '${Formatters.integer.format(total)}',
                    style: muted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Spacer(),
              if (!compact) ...[
                Text('Filas por página', style: muted),
                const SizedBox(width: 8),
              ],
              Tooltip(
                message: 'Filas por página',
                child: DropdownButton<int>(
                  value: rowsPerPage,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(8),
                  focusColor: Colors.transparent,
                  items: [
                    for (final value in ProductsTable.rowsPerPageOptions)
                      DropdownMenuItem(value: value, child: Text('$value')),
                  ],
                  onChanged: (value) {
                    if (value != null) onRowsPerPageChanged(value);
                  },
                ),
              ),
              SizedBox(width: compact ? 8 : 24),
              if (!compact)
                IconButton(
                  tooltip: 'Primera página',
                  onPressed: canGoBack ? () => onPageChanged(0) : null,
                  icon: const Icon(Icons.first_page),
                ),
              IconButton(
                tooltip: 'Página anterior',
                onPressed: canGoBack
                    ? () => onPageChanged(currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  compact
                      ? '${currentPage + 1} / $totalPages'
                      : 'Página ${currentPage + 1} de $totalPages',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Página siguiente',
                onPressed: canGoForward
                    ? () => onPageChanged(currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
              if (!compact)
                IconButton(
                  tooltip: 'Última página',
                  onPressed: canGoForward
                      ? () => onPageChanged(totalPages - 1)
                      : null,
                  icon: const Icon(Icons.last_page),
                ),
            ],
          ),
        );
      },
    );
  }
}
