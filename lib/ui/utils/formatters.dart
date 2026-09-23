import 'package:intl/intl.dart';

/// Formateadores compartidos por la tabla, las tarjetas de resumen y la
/// exportación, para que los valores se muestren igual en toda la app.
class Formatters {
  Formatters._();

  static final NumberFormat currency = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat quantity = NumberFormat('#,##0.##', 'es_MX');

  static final NumberFormat integer = NumberFormat('#,##0', 'es_MX');

  static final DateFormat _date = DateFormat('dd/MM/yyyy');

  static String date(DateTime? value) =>
      value == null ? '-' : _date.format(value);

  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
