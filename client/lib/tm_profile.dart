import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class TmProfile extends StatefulWidget {
  final Global global;
  final VoidCallback callback;
  final List<String>? initialData;

  const TmProfile(this.global, this.callback, {this.initialData, super.key});

  @override
  State<TmProfile> createState() => StateTmProfile();
}

class StateTmProfile extends State<TmProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  // We will now store structured TM data instead of just raw strings in a single controller.
  // Although we still need to serialize to the raw string format on save.
  // Format: "TM1:Mnemonic1,TM1:Mnemonic2,TM2:Mnemonic3"
  
  // State for PreRequisiteTM
  List<Map<String, String>> _preTmItems = []; // [{'tm': 'TM1', 'mnemonic': 'abc'}, ...]
  
  // State for LogTM
  List<Map<String, String>> _logTmItems = [];

  final List<String> _tmTypes = ['TM1', 'TM2', 'TM3', 'TM4', 'TM5', 'TM6'];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!.isNotEmpty && widget.global.rowSelected.isNotEmpty) {
       if (widget.initialData!.length > 1) _nameController.text = widget.initialData![1];
       if (widget.initialData!.length > 2) _preTmItems = _parseTmString(widget.initialData![2]);
       if (widget.initialData!.length > 3) _logTmItems = _parseTmString(widget.initialData![3]);
    } else {
       if (widget.global.rowSelected.isNotEmpty) {
          sendRequest();
       }
    }
  }

  // Parse string "TM1:Mnemonic1,TM2:Mnemonic3" into list of maps
  List<Map<String, String>> _parseTmString(String raw) {
    if (raw.isEmpty || raw == "NULL") return [];
    List<Map<String, String>> items = [];
    List<String> parts = raw.split(',');
    for (var p in parts) {
      var subParts = p.split(':');
      if (subParts.length >= 2) {
        items.add({'tm': subParts[0].trim(), 'mnemonic': subParts.sublist(1).join(':').trim()});
      } else if (p.trim().isNotEmpty) {
         // Fallback for malformed data
         items.add({'tm': 'TM1', 'mnemonic': p.trim()});
      }
    }
    return items;
  }

  String _serializeTmList(List<Map<String, String>> items) {
    if (items.isEmpty) return "";
    return items.map((e) => "${e['tm']}:${e['mnemonic']}").join(",");
  }

  void sendRequest() async {
    try {
      RowDisplayRequest req = RowDisplayRequest();
      req.id = widget.global.clientID;
      var tableName = getTableName(widget.global.tableSelected);
      req.tableName = tableName;
      req.primaryKey = widget.global.rowSelected;

      if (widget.global.rowSelected == '') return;

      final response = await http.post(
        Uri.parse('${Uri.base.origin}/getRows'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(req.toJSON()),
      );

      if (response.statusCode == 200) {
        var temp = RowDisplayDetails.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        if (temp.ok) {
          _nameController.text = temp.values[0];
          _preTmItems = _parseTmString(temp.values[1]);
          _logTmItems = _parseTmString(temp.values[2]);
          setState(() {});
        } else {
          showMessage(temp.message, true);
        }
      } else {
        showMessage("Server Returned Negative ACK", true);
      }
    } on Exception catch (e) {
      debugPrint('$e');
      showMessage("Server Failed", true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
             decoration: BoxDecoration(
               color: Colors.white,
               border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
             ),
             child: Text(
               widget.global.rowSelected.isEmpty ? "Create TM Profile" : "Edit TM Profile", 
               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
             ),
          ),
          
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: "TM Profile Name",
                      validator: (value) => (value == null || value.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 24),
                    _buildTmListEditor("Pre Requisite TM", _preTmItems),
                    const SizedBox(height: 24),
                    _buildTmListEditor("Log TM", _logTmItems),
                  ],
                ),
              ),
            ),
          ),
          
          Container(
             decoration: BoxDecoration(
               color: Colors.grey.shade50,
               border: Border(top: BorderSide(color: Colors.grey.shade200)),
             ),
             child: Padding(
               padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
               child: Row(
                 children: [
                   Expanded(
                     child: OutlinedButton(
                       onPressed: () {
                         widget.global.subMode = SubModes.showTables;
                         widget.callback();
                       },
                       style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                       child: const Text("Cancel"),
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: FilledButton.icon(
                       onPressed: _handleSave,
                       icon: Icon(widget.global.rowSelected.isEmpty ? Icons.add : Icons.save, size: 20),
                       label: Text(widget.global.rowSelected.isEmpty ? "Insert" : "Save Changes"),
                       style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                     ),
                   ),
                 ],
               ),
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildTmListEditor(String title, List<Map<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (ctx, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: items[index]['tm'],
                        isExpanded: true,
                        items: _tmTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setState(() => items[index]['tm'] = val!),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: items[index]['mnemonic'],
                      decoration: InputDecoration(
                        hintText: "Mnemonic",
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      onChanged: (val) => items[index]['mnemonic'] = val,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => setState(() => items.removeAt(index)),
                  )
                ],
              ),
            );
          },
        ),
        OutlinedButton.icon(
          onPressed: () => setState(() => items.add({'tm': 'TM1', 'mnemonic': ''})),
          icon: const Icon(Icons.add, size: 16),
          label: const Text("Add TM Mnemonic"),
        )
      ],
    );
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      showMessage("Please check the inputs", true);
      return;
    }
    
    // Filter out empty mnemonics
    var preValues = _preTmItems.where((e) => e['mnemonic']!.isNotEmpty).toList();
    var logValues = _logTmItems.where((e) => e['mnemonic']!.isNotEmpty).toList();
    
    // Serialize
    String preStr = _serializeTmList(preValues);
    String logStr = _serializeTmList(logValues);

    var clientID = widget.global.clientID;
    var tableName = getTableName(widget.global.tableSelected);
    List<String> values = [];
    values.add("0"); // Placeholder for ID (Index 0)
    values.add(_nameController.text); // Index 1
    values.add(preStr); // Index 2
    values.add(logStr); // Index 3
    
    bool edit = widget.global.rowSelected.isNotEmpty;
    bool ok;
    if (edit) {
      ok = await sendUpdateRequest(clientID, tableName, values, primaryKey: widget.global.rowSelected);
    } else {
      ok = await sendAddRequest(clientID, tableName, values);
    }
    
    if (ok) {
        widget.global.subMode = SubModes.showTables;
        widget.callback();
    }
  }
}
