import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:xml_parser/main.dart';
import 'package:xml_parser/ui/widgets/xml_upload_dialog.dart';

class TitleBar extends StatelessWidget {
  final VoidCallback onProductsAdded;

  const TitleBar({super.key, required this.onProductsAdded});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Lector de Productos CFDI"),
        Row(
          children: [
            IconButton(
              onPressed: () {
                MyApp.of(context)?.toggleTheme();
              },
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              tooltip: 'Cambiar tema',
            ),
            SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  type: FileType.custom,
                  allowedExtensions: ['xml'],
                );
                if (result != null) {
                  List<File> files = result.paths.map((path) => File(path!)).toList();
                  if (context.mounted) {
                    final shouldReload = await showDialog<bool>(
                      context: context,
                      builder: (context) => XMLUploadDialog(files: files),
                    );
                    if (shouldReload == true) {
                      onProductsAdded();
                    }
                  }
                }
              },
              label: Text("Cargar XML"),
              icon: Icon(Icons.upload_file),
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  Color.fromARGB(255, 53, 95, 177),
                ),
                foregroundColor: WidgetStatePropertyAll(Colors.white),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
