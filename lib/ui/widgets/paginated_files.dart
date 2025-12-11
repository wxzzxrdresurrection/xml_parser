import 'package:flutter/material.dart';
import 'dart:io';

class FilesPaginatedGrid extends StatelessWidget {
  final List<File> files;
  final void Function(File) onDelete;

  const FilesPaginatedGrid({
    super.key,
    required this.files,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: files.map((file) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Icon(Icons.insert_drive_file, size: 40, color: Colors.blue),
              SizedBox(height: 8),
              Text(
                file.path.split('/').last,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => onDelete(file),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.red),
                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                icon: Icon(Icons.delete),
                label: Text('Eliminar'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}