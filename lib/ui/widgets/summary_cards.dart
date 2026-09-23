import 'package:flutter/material.dart';
import 'package:xml_parser/models/products.dart';
import 'package:xml_parser/ui/utils/formatters.dart';

/// Fila de indicadores calculados sobre los productos visibles (filtrados).
class SummaryCards extends StatelessWidget {
  final List<Product> products;
  final int totalProducts;

  const SummaryCards({
    super.key,
    required this.products,
    required this.totalProducts,
  });

  @override
  Widget build(BuildContext context) {
    final invoices = products
        .map((p) => p.invoiceUuid)
        .whereType<String>()
        .toSet()
        .length;
    final suppliers = products
        .map((p) => (p.supplierName ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .length;
    final amount = products.fold<double>(0, (sum, p) => sum + p.totalAmount);
    final isFiltered = products.length != totalProducts;

    final cards = [
      (
        icon: Icons.inventory_2_outlined,
        label: 'Productos',
        value: Formatters.integer.format(products.length),
        caption: isFiltered
            ? 'de ${Formatters.integer.format(totalProducts)} registrados'
            : 'registrados',
      ),
      (
        icon: Icons.receipt_outlined,
        label: 'Facturas',
        value: Formatters.integer.format(invoices),
        caption: 'UUID únicos',
      ),
      (
        icon: Icons.storefront_outlined,
        label: 'Proveedores',
        value: Formatters.integer.format(suppliers),
        caption: 'distintos',
      ),
      (
        icon: Icons.payments_outlined,
        label: 'Importe total',
        value: Formatters.currency.format(amount),
        caption: isFiltered ? 'según filtros' : 'de todos los productos',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // En ventanas angostas las tarjetas se compactan (sin icono ni
        // leyenda) para dejarle más espacio vertical a la tabla.
        final compact = constraints.maxWidth < 1000;
        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  icon: cards[i].icon,
                  label: cards[i].label,
                  value: cards[i].value,
                  caption: cards[i].caption,
                  compact: compact,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final bool compact;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Se lee como una sola frase: "Productos, 60, registrados".
    return MergeSemantics(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 14),
          child: Row(
            children: [
              if (!compact) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    if (!compact)
                      Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
