import 'package:flutter/material.dart';

class ImportLossDialog extends StatelessWidget {
  const ImportLossDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Options'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, 'PREVIOUS_PHASE');
            },
            icon: const Icon(Icons.history),
            label: const Text('Copy from Previous Test Phase'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, 'EXCEL');
            },
            icon: const Icon(Icons.file_upload),
            label: const Text('Import from Excel/CSV'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, 'MANUAL_ENTRY');
            },
            icon: const Icon(Icons.edit),
            label: const Text('Add Losses Manually (UI)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
