import 'package:flutter/material.dart';

class CustomPaginatedTable extends StatefulWidget {
  final List<DataColumn> columns;
  final List<List<dynamic>> rows;
  final int rowsPerPage;

  const CustomPaginatedTable({
    super.key,
    required this.columns,
    required this.rows,
    this.rowsPerPage = 10,
  });

  @override
  State<CustomPaginatedTable> createState() => _CustomPaginatedTableState();
}

class _CustomPaginatedTableState extends State<CustomPaginatedTable> {
  int _currentPage = 0;
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _rowsPerPage = widget.rowsPerPage;
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = (widget.rows.length / _rowsPerPage).ceil();
    int startIndex = _currentPage * _rowsPerPage;
    int endIndex = startIndex + _rowsPerPage;

    final pageRows = widget.rows.sublist(
      startIndex,
      endIndex > widget.rows.length ? widget.rows.length : endIndex,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Total: ${widget.rows.length} productos',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                ),
                SizedBox(width: 16),
                Container(height: 20, width: 1, color: Colors.grey),
                SizedBox(width: 16),
                Text(
                  'Filas por página:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                ),
                SizedBox(width: 8),
                DropdownButton<int>(
                  value: _rowsPerPage,
                  underline: Container(),
                  items: [10, 20, 50].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value'),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _rowsPerPage = newValue;
                        _currentPage = 0;
                      });
                    }
                  },
                ),
                SizedBox(width: 16),
                Text(
                  'Página ${_currentPage + 1} de $totalPages',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                  icon: const Icon(Icons.arrow_back),
                ),
                IconButton(
                  onPressed: _currentPage < totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ],
        ),

        DataTable(
          columnSpacing: 12,
          horizontalMargin: 12,
          headingRowHeight: 48,
          headingRowColor: WidgetStateProperty.resolveWith(
            (states) => Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.grey[200],
          ),
          columns: widget.columns.asMap().entries.map((entry) {
            final index = entry.key;
            final col = entry.value;

            double width;
            if (index == 0) {
              width = 50;   // ID
            } else if (index == 1) {
              width = 180;  // Proveedor
            } else if (index == 2) {
              width = 200;  // Descripción
            } else if (index == 3 || index == 4) {
              width = 90;   // Claves
            } else if (index == 5 || index == 6 || index == 7) {
              width = 90;   // Cantidad, Valores
            } else if (index == 8 || index == 11) {
              width = 110;  // Fechas
            } else if (index == 9) {
              width = 90;   // Folio
            } else if (index == 10) {
              width = 220;  // UUID
            } else {
              width = 90;
            }

            return DataColumn(
              label: SizedBox(
                width: width,
                child: Text(
                  (col.label as Text).data ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
          rows: const [], // 👈 IMPORTANTE: sin filas
        ),

        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columnSpacing: 12,
                horizontalMargin: 12,
                dataRowMinHeight: 48,
                dataRowMaxHeight: double.infinity,
                headingRowHeight: 0,
                columns: widget.columns
                    .map((_) => const DataColumn(label: SizedBox.shrink()))
                    .toList(),
                rows: pageRows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final r = entry.value;

                  return DataRow(
                    color: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2);
                      }
                      return index.isEven
                          ? Colors.transparent
                          : Theme.of(context).dividerColor.withOpacity(0.04);
                    }),
                    cells: r.asMap().entries.map((entry) {
                      final colIndex = entry.key;
                      final c = entry.value;

                      double width;
                      if (colIndex == 0) {
                        width = 50;   // ID
                      } else if (colIndex == 1) {
                        width = 180;  // Proveedor
                      } else if (colIndex == 2) {
                        width = 200;  // Descripción
                      } else if (colIndex == 3 || colIndex == 4) {
                        width = 90;   // Claves
                      } else if (colIndex == 5 || colIndex == 6 || colIndex == 7) {
                        width = 90;   // Cantidad, Valores
                      } else if (colIndex == 8 || colIndex == 11) {
                        width = 110;  // Fechas
                      } else if (colIndex == 9) {
                        width = 90;   // Folio
                      } else if (colIndex == 10) {
                        width = 220;  // UUID
                      } else {
                        width = 90;
                      }
                      return DataCell(
                        SizedBox(
                          width: width,
                          child: SelectableText(
                            '$c',
                            style: TextStyle(fontSize: 13),
                            maxLines: null, // Sin límite de líneas
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        SizedBox(height: 48),
      ],
    );
  }
}
