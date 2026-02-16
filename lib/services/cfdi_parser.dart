import 'package:xml/xml.dart';
import 'package:xml_parser/services/db.dart';
import '../models/products.dart';

class CfdiParser {
  static Future<List<dynamic>> parse(String xmlString) {
    final doc = XmlDocument.parse(xmlString);
    final conceptos = doc.findAllElements('cfdi:Concepto');

    final comprobantes = doc.findAllElements('cfdi:Comprobante');
    final comprobante = comprobantes.isNotEmpty ? comprobantes.first : null;

    final emisores = doc.findAllElements('cfdi:Emisor');
    final emisor = emisores.isNotEmpty ? emisores.first : null;

    final timbres = doc.findAllElements('tfd:TimbreFiscalDigital');
    final timbre = timbres.isNotEmpty ? timbres.first : null;

    String? emptyToNull(String? value) {
      if (value == null) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    DateTime? parseDate(String? value) {
      if (value == null) return null;
      return DateTime.tryParse(value);
    }

    final supplierName = emptyToNull(emisor?.getAttribute('Nombre'));
    final invoiceDate = parseDate(comprobante?.getAttribute('Fecha'));
    final invoiceFolio = '${comprobante?.getAttribute('Serie') ?? ''} - ${comprobante?.getAttribute('Folio') ?? ''}';
    final invoiceUuid = emptyToNull(timbre?.getAttribute('UUID'));

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
        supplierName: supplierName,
        invoiceDate: invoiceDate,
        invoiceFolio: invoiceFolio,
        invoiceUuid: invoiceUuid,
      );
    }).toList();

    return DatabaseHelper.instance.insertProducts(products);
  }
}