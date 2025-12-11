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

  @override
  Widget build(BuildContext context) {
    int totalPages = (widget.rows.length / widget.rowsPerPage).ceil();
    int startIndex = _currentPage * widget.rowsPerPage;
    int endIndex = startIndex + widget.rowsPerPage;

    final pageRows = widget.rows.sublist(
      startIndex,
      endIndex > widget.rows.length ? widget.rows.length : endIndex,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 📌 Contenedor toma solo el tamaño necesario
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(blurRadius: 3, spreadRadius: 1, color: Colors.black12),
            ],
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          ),

          child: LayoutBuilder(
            builder: (context, constraints) {
              final table = DataTable(
                columnSpacing: 16,
                horizontalMargin: 12,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                headingRowColor: MaterialStateProperty.resolveWith(
                  (states) => Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.grey[200],
                ),
                columns: widget.columns,
                                rows: pageRows.map((r) {
                  return DataRow(
                    cells: r.asMap().entries.map((entry) {
                      final index = entry.key;
                      final c = entry.value;

                      // La columna de descripción es la segunda (índice 1)
                      final isDescription = index == 1;

                      return DataCell(
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isDescription ? 300 : 150, // Más espacio para descripción
                          ),
                          child: SelectableText(
                            '$c',
                            style: TextStyle(fontSize: 14),
                            maxLines: isDescription ? null : 2, // Sin límite de líneas para descripción
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              );

              final tableWidth = _calculateTableWidth(table);

              final mustScroll = tableWidth > constraints.maxWidth;

              return SingleChildScrollView(
                scrollDirection: mustScroll ? Axis.horizontal : Axis.vertical,
                child: SizedBox(
                  width: mustScroll ? tableWidth : constraints.maxWidth,
                  child: table,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Página ${_currentPage + 1} de $totalPages',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium!.color,
              ),
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
      ],
    );
  }

    double _calculateTableWidth(DataTable table) {
      double totalWidth = 24;

    for (int i = 0; i < table.columns.length; i++) {

      totalWidth += (i == 1) ? 300 : 150;
      if (i < table.columns.length - 1) {
        totalWidth += 16;
      }
    }

    return totalWidth;
  }
}
