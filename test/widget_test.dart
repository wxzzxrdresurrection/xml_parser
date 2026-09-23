import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xml_parser/models/products.dart';
import 'package:xml_parser/ui/theme/app_theme.dart';
import 'package:xml_parser/ui/widgets/empty_state.dart';
import 'package:xml_parser/ui/widgets/products_table.dart';

Product _product(int id, {String? supplier, DateTime? date, double total = 0}) {
  return Product(
    id: id,
    description: 'Producto $id',
    identificationNumber: '5010${id.toString().padLeft(4, '0')}',
    unitCode: 'H87',
    unitName: 'Pieza',
    quantity: 1,
    unitPrice: total,
    totalAmount: total,
    createdAt: DateTime(2025, 1, 1),
    supplierName: supplier,
    invoiceDate: date,
    invoiceFolio: 'A - $id',
    invoiceUuid: 'uuid-$id',
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: SizedBox(width: 1600, height: 900, child: child)),
  );
}

void main() {
  group('sortProducts', () {
    test('ordena por importe y deja los nulos al final', () {
      final list = [
        _product(1, total: 30),
        _product(2, total: 10),
        _product(3, total: 20),
      ];
      sortProducts(list, 7, true);
      expect(list.map((p) => p.id), [2, 3, 1]);
      sortProducts(list, 7, false);
      expect(list.map((p) => p.id), [1, 3, 2]);
    });

    test('las fechas vacías quedan al final en ambas direcciones', () {
      final list = [
        _product(1, date: null),
        _product(2, date: DateTime(2024, 5, 1)),
        _product(3, date: DateTime(2025, 5, 1)),
      ];
      sortProducts(list, 8, true);
      expect(list.map((p) => p.id), [2, 3, 1]);
      sortProducts(list, 8, false);
      expect(list.map((p) => p.id), [3, 2, 1]);
    });
  });

  testWidgets('ProductsTable pagina y notifica el ordenamiento', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final products = List.generate(30, (i) => _product(i + 1, total: i + 1.0));
    int? sortedColumn;
    bool? sortedAscending;

    await tester.pumpWidget(
      _wrap(
        ProductsTable(
          products: products,
          initialRowsPerPage: 10,
          onSort: (column, ascending) {
            sortedColumn = column;
            sortedAscending = ascending;
          },
        ),
      ),
    );

    expect(find.text('Mostrando 1–10 de 30'), findsOneWidget);
    expect(find.text('Página 1 de 3'), findsOneWidget);
    expect(find.text('Producto 1'), findsOneWidget);
    expect(find.text('Producto 11'), findsNothing);

    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Página 2 de 3'), findsOneWidget);
    expect(find.text('Producto 11'), findsOneWidget);

    await tester.tap(find.byTooltip('Última página'));
    await tester.pumpAndSettle();
    expect(find.text('Mostrando 21–30 de 30'), findsOneWidget);

    await tester.tap(find.text('Importe'));
    await tester.pump();
    expect(sortedColumn, 7);
    expect(sortedAscending, isTrue);
  });

  testWidgets('EmptyState muestra la acción', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        EmptyState(
          icon: Icons.upload_file,
          title: 'Aún no hay productos',
          message: 'Carga archivos XML',
          actionLabel: 'Cargar XML',
          onAction: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Aún no hay productos'), findsOneWidget);
    await tester.tap(find.text('Cargar XML'));
    expect(tapped, isTrue);
  });
}
