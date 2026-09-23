import 'package:flutter/material.dart';
import 'package:xml_parser/main.dart';

class TitleBar extends StatelessWidget {
  final VoidCallback onUploadPressed;

  const TitleBar({super.key, required this.onUploadPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.receipt_long, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lector de Productos CFDI',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Importa facturas XML y exporta sus conceptos a Excel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => MyApp.of(context)?.toggleTheme(theme.brightness),
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
          tooltip: isDark ? 'Cambiar a tema claro' : 'Cambiar a tema oscuro',
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Cargar archivos XML (Ctrl+O)',
          child: FilledButton.icon(
            onPressed: onUploadPressed,
            label: const Text('Cargar XML'),
            icon: const Icon(Icons.upload_file),
          ),
        ),
      ],
    );
  }
}
