import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:xml_parser/services/cfdi_parser.dart';
import 'package:xml_parser/ui/theme/app_theme.dart';
import 'package:xml_parser/ui/utils/formatters.dart';

/// Abre el selector de archivos y, si el usuario elige XMLs, muestra el
/// diálogo de carga. Llama a [onProductsAdded] si se guardó algún producto.
Future<void> pickAndUploadXml(
  BuildContext context, {
  required VoidCallback onProductsAdded,
}) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Selecciona facturas XML (CFDI)',
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: ['xml'],
  );
  if (result == null || !context.mounted) return;

  final files = result.paths.whereType<String>().map(File.new).toList();
  if (files.isEmpty) return;

  final added = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => XMLUploadDialog(files: files),
  );
  if (added == true) onProductsAdded();
}

enum _UploadStage { review, processing, done }

class _FileError {
  final String fileName;
  final String message;

  const _FileError(this.fileName, this.message);
}

class XMLUploadDialog extends StatefulWidget {
  const XMLUploadDialog({super.key, required this.files});

  final List<File> files;

  @override
  State<XMLUploadDialog> createState() => _XMLUploadDialogState();
}

class _XMLUploadDialogState extends State<XMLUploadDialog> {
  late final List<File> _files = List.of(widget.files);
  _UploadStage _stage = _UploadStage.review;

  int _processed = 0;
  String? _currentFile;
  int _productsAdded = 0;
  int _filesOk = 0;
  final List<_FileError> _errors = [];

  String _name(File file) => p.basename(file.path);

  String _size(File file) {
    try {
      return Formatters.fileSize(file.lengthSync());
    } catch (_) {
      return '';
    }
  }

  Future<void> _process() async {
    setState(() => _stage = _UploadStage.processing);

    for (final file in _files) {
      setState(() => _currentFile = _name(file));
      try {
        final content = await file.readAsString();
        final results = await CfdiParser.parse(content);
        final inserted = results.whereType<int>().length;
        if (inserted == 0) {
          _errors.add(
            _FileError(_name(file), 'No se encontraron conceptos en el XML.'),
          );
        } else {
          _productsAdded += inserted;
          _filesOk++;
        }
      } on FormatException {
        _errors.add(_FileError(_name(file), 'El archivo no es un XML válido.'));
      } on FileSystemException catch (e) {
        _errors.add(
          _FileError(_name(file), 'No se pudo leer el archivo (${e.message}).'),
        );
      } catch (e) {
        _errors.add(_FileError(_name(file), e.toString()));
      }
      if (!mounted) return;
      setState(() => _processed++);
    }

    setState(() {
      _currentFile = null;
      _stage = _UploadStage.done;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stage != _UploadStage.processing,
      child: AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        title: Text(switch (_stage) {
          _UploadStage.review => 'Cargar archivos XML',
          _UploadStage.processing => 'Procesando archivos…',
          _UploadStage.done => 'Carga finalizada',
        }),
        content: SizedBox(
          width: 560,
          child: switch (_stage) {
            _UploadStage.review => _buildReview(context),
            _UploadStage.processing => _buildProgress(context),
            _UploadStage.done => _buildSummary(context),
          },
        ),
        actions: switch (_stage) {
          _UploadStage.review => [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: _files.isEmpty ? null : _process,
              icon: const Icon(Icons.playlist_add_check),
              label: Text(
                _files.length == 1
                    ? 'Procesar 1 archivo'
                    : 'Procesar ${_files.length} archivos',
              ),
            ),
          ],
          _UploadStage.processing => const [],
          _UploadStage.done => [
            FilledButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(_productsAdded > 0),
              child: const Text('Listo'),
            ),
          ],
        },
      ),
    );
  }

  Widget _buildReview(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revisa los archivos seleccionados. Puedes quitar los que no '
          'quieras importar antes de procesarlos.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(maxHeight: 360),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          child: _files.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No hay archivos para procesar.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _files.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.description_outlined,
                        color: scheme.primary,
                      ),
                      title: Text(
                        _name(file),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_size(file)),
                      trailing: IconButton(
                        tooltip: 'Quitar de la lista',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _files.removeAt(index)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProgress(BuildContext context) {
    final theme = Theme.of(context);
    final total = _files.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: total == 0 ? null : _processed / total,
          semanticsLabel: 'Progreso de la carga',
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 12),
        Text(
          'Archivo ${_processed < total ? _processed + 1 : total} de $total',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_currentFile != null) ...[
          const SizedBox(height: 4),
          Text(
            _currentFile!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final success = _productsAdded > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.info_outline,
              color: success ? AppTheme.success : scheme.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success
                    ? 'Se agregaron ${Formatters.integer.format(_productsAdded)} '
                          'productos de $_filesOk '
                          '${_filesOk == 1 ? 'archivo' : 'archivos'}.'
                    : 'No se agregaron productos.',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        if (_errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '${_errors.length} '
            '${_errors.length == 1 ? 'archivo no se pudo' : 'archivos no se pudieron'} '
            'procesar:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                for (final error in _errors)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.error_outline, color: scheme.error),
                    title: Text(error.fileName),
                    subtitle: Text(error.message),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
