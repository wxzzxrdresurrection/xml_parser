import 'package:xml/xml.dart';
import 'package:xml_parser/services/db.dart';
import '../models/products.dart';

class CfdiParser {
  static Future<List<dynamic>> parse(String xmlString) {
    final doc = XmlDocument.parse(xmlString);
    final conceptos = doc.findAllElements('cfdi:Concepto');

    final products = conceptos.map((c) {
      return Product(
        description: c.getAttribute('Descripcion') ?? '',
        identificationNumber: c.getAttribute('ClaveProdServ') ?? '',
        unitCode: c.getAttribute('ClaveUnidad') ?? '',
        unitName: c.getAttribute('Unidad') ?? '',
        quantity: double.tryParse(c.getAttribute('Cantidad') ?? '0') ?? 0,
        unitPrice: double.tryParse(c.getAttribute('ValorUnitario') ?? '0') ?? 0,
        totalAmount: double.tryParse(c.getAttribute('Importe') ?? '0') ?? 0,
        createdAt: DateTime.now(),
      );
    }).toList();

    return DatabaseHelper.instance.insertProducts(products);
  }
}
