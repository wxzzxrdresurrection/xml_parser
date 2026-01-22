import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:xml_parser/models/products.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class ExcelCreator {
  static Future<String?> createExcel(List<Product> products, List<DataColumn> headers) async {
    var excel = Excel.createExcel();
    String sheetName = 'Productos';
    Sheet sheetObject = excel[sheetName];

    // Estilos para el encabezado
    CellStyle headerStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 12,
      bold: true,
      textWrapping: TextWrapping.WrapText,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
      fontColorHex: ExcelColor.white,
    );

    // Estilo para las filas de datos
    CellStyle dataStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    // Estilo para números
    CellStyle numberStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    // Estilo para filas alternadas
    CellStyle alternateRowStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#F2F2F2'),
    );

    CellStyle alternateNumberStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#F2F2F2'),
    );

    // Formatters
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final quantityFormatter = NumberFormat('#,##0.00', 'es_MX');

    // Agregar encabezados
    List<String> headerTitles = [
      'ID',
      'Descripción',
      'Clave ProdServ',
      'Clave Unidad',
      'Cantidad',
      'Valor Unitario',
      'Importe',
      'Fecha de Registro'
    ];

    for (int i = 0; i < headerTitles.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headerTitles[i]);
      cell.cellStyle = headerStyle;
    }

    // Agregar datos
    for (int i = 0; i < products.length; i++) {
      Product product = products[i];
      int rowIndex = i + 1;
      bool isAlternateRow = i % 2 == 1;

      // Columna 0: ID
      var cellId = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      cellId.value = IntCellValue(product.id ?? 0);
      cellId.cellStyle = isAlternateRow ? alternateNumberStyle : numberStyle;

      // Columna 1: Descripción
      var cellDesc = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      cellDesc.value = TextCellValue(product.description);
      cellDesc.cellStyle = isAlternateRow ? alternateRowStyle : dataStyle;

      // Columna 2: Clave ProdServ
      var cellIdNum = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
      cellIdNum.value = TextCellValue(product.identificationNumber);
      cellIdNum.cellStyle = isAlternateRow ? alternateRowStyle : dataStyle;

      // Columna 3: Clave Unidad
      var cellUnitCode = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
      cellUnitCode.value = TextCellValue(product.unitCode);
      cellUnitCode.cellStyle = isAlternateRow ? alternateRowStyle : dataStyle;

      // Columna 4: Cantidad
      var cellQty = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
      cellQty.value = TextCellValue(quantityFormatter.format(product.quantity));
      cellQty.cellStyle = isAlternateRow ? alternateNumberStyle : numberStyle;

      // Columna 5: Valor Unitario
      var cellPrice = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex));
      cellPrice.value = TextCellValue(currencyFormatter.format(product.unitPrice));
      cellPrice.cellStyle = isAlternateRow ? alternateNumberStyle : numberStyle;

      // Columna 6: Importe
      var cellTotal = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex));
      cellTotal.value = TextCellValue(currencyFormatter.format(product.totalAmount));
      cellTotal.cellStyle = isAlternateRow ? alternateNumberStyle : numberStyle;

      // Columna 7: Fecha
      var cellDate = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex));
      cellDate.value = TextCellValue(dateFormatter.format(product.createdAt));
      cellDate.cellStyle = isAlternateRow ? alternateRowStyle : dataStyle;
    }

    // Ajustar ancho de columnas
    sheetObject.setColumnWidth(0, 8);   // ID
    sheetObject.setColumnWidth(1, 40);  // Descripción
    sheetObject.setColumnWidth(2, 18);  // Clave ProdServ
    sheetObject.setColumnWidth(3, 15);  // Clave Unidad
    sheetObject.setColumnWidth(4, 12);  // Cantidad
    sheetObject.setColumnWidth(5, 16);  // Valor Unitario
    sheetObject.setColumnWidth(6, 16);  // Importe
    sheetObject.setColumnWidth(7, 18);  // Fecha

    // Save the file
    List<int>? fileBytes = excel.encode();
    if (fileBytes == null) {
      throw Exception("Error encoding Excel file");
    }

    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar archivo Excel',
      fileName: 'productos_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (outputPath != null) {
      final file = File(outputPath);
      await file.writeAsBytes(fileBytes, flush: true);
      return outputPath;
    }

    return null;

  }
}