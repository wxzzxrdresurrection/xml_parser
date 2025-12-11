import 'dart:io';
import 'package:flutter/material.dart';
import 'package:xml_parser/services/cfdi_parser.dart';
import 'package:xml_parser/ui/widgets/paginated_files.dart';

class XMLUploadDialog extends StatelessWidget {
  const XMLUploadDialog({super.key, required this.files});

  final List<File> files;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: Text('Carga de archivos XML (${files.length})'),
          content: SizedBox(
            width: 800,
            height: 400,
            child: SingleChildScrollView(
              child: FilesPaginatedGrid(
                files: files,
                onDelete: (file) {
                  setStateDialog(() {
                    files.remove(file);
                    if (files.isEmpty) {
                      Navigator.of(context).pop();
                    }
                  });
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar'),
            ),
            TextButton(
              onPressed: () async {
                final List<dynamic> results = [];
                for (var file in files) {
                  String xmlContent = file.readAsStringSync();
                  results.addAll(await CfdiParser.parse(xmlContent));
                }
                if (results.isNotEmpty && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Se agregaron ${results.whereType<int>().length} productos.'),
                    ),
                  );
                  Navigator.of(context).pop(true);
                } else {
                  if (context.mounted){
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('No se agregaron productos.'),
                      ),
                    );
                  }
                }
              },
              child: Text('Procesar XML'),
            ),
          ],
        );
      },
    );
  }
}
