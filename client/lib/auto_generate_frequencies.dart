import 'package:flutter/material.dart';

import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/variables.dart';

class AutoGenerateFrequencies extends StatefulWidget {
  final Global global;
  final VoidCallback callback;

  const AutoGenerateFrequencies(this.global, this.callback, {super.key});

  @override
  State<AutoGenerateFrequencies> createState() =>
      StateAutoGenerateFrequencies();
}

class StateAutoGenerateFrequencies extends State<AutoGenerateFrequencies> {
  bool _addGPSFrequencies = false;

  @override
  void initState() {
    super.initState();
  }

  void update() async {
    var clientID = widget.global.clientID;
    var tableName = "CableCalibrationFrequenciesAuto";
    List<String> values = [];
    values.add((_addGPSFrequencies) ? "Yes" : "No");
    var ok = await sendUpdateRequest(clientID, tableName, values);
    if (ok) {
      setState(() {});
    }
  }

  Widget getButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                widget.global.subMode = SubModes.showTables;
                widget.callback();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Cancel", style: TextStyle(color: Colors.black87)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                update();
              },
              icon: const Icon(Icons.flash_on, size: 20),
              label: const Text("Generate Now"),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var button = getButton(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
             decoration: BoxDecoration(
               color: Colors.white,
               border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
             ),
             child: const Text(
               "Auto Generate Frequencies", 
               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
             ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Caution: Auto Populate will remove existing entries for this configuration.',
                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: CheckboxListTile(
                      value: _addGPSFrequencies,
                      onChanged: (value) {
                        _addGPSFrequencies = value ?? false;
                        setState(() {});
                      },
                      title: const Text("Include SPS (Standard Positioning Service)"),
                      subtitle: const Text("Generate additional GPS-specific frequencies", style: TextStyle(fontSize: 12)),
                      controlAffinity: ListTileControlAffinity.leading,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Container(
             decoration: BoxDecoration(
               color: Colors.grey.shade50,
               border: Border(top: BorderSide(color: Colors.grey.shade200)),
             ),
             child: button
          ),
        ],
      ),
    );
  }
}
