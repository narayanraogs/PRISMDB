import 'package:flutter/material.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/up_link_losses.dart';
import 'package:prism_db_editor/uplink_loss_upload.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:prism_db_editor/widgets/import_loss_dialog.dart';

class LossWrapper extends StatefulWidget {
  final Global global;
  final VoidCallback callback;

  const LossWrapper({super.key, required this.global, required this.callback});

  @override
  State<LossWrapper> createState() => _LossWrapperState();
}

class _LossWrapperState extends State<LossWrapper> {
  String? _mode;

  @override
  void initState() {
    super.initState();
    // If editing, skip dialog entirely and jump straight to standard manual UpLinkLosses editor
    if (widget.global.rowSelected.isNotEmpty) {
      _mode = 'MANUAL_ENTRY';
    } else {
      // Small timeout to allow the widget to mount before showing dialog
      Future.delayed(Duration.zero, _showImportDialog);
    }
  }

  Future<void> _showImportDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const ImportLossDialog(),
    );

    if (result == null) {
      // User cancelled
      widget.callback();
      return;
    }

    if (mounted) {
      setState(() {
        _mode = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mode == 'EXCEL') {
      // Assuming UpLinkLossUpload handles Excel importing (as requested by Excel logic lookup previously)
      return UpLinkLossUpload(widget.global, widget.callback);
    } else if (_mode == 'PREVIOUS_PHASE') {
      return UpLinkLosses(widget.global, widget.callback, isCopyMode: true);
    } else { // 'MANUAL_ENTRY'
      return UpLinkLosses(widget.global, widget.callback);
    }
  }
}
