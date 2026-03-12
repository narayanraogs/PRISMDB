import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:prism_db_editor/services/api_service.dart';

class EditTRMProfile extends StatefulWidget {
  final Global global;
  final VoidCallback callback;
  final List<String>? initialData;

  const EditTRMProfile(this.global, this.callback, {super.key, this.initialData});

  @override
  State<EditTRMProfile> createState() => _EditTRMProfileState();
}

class _EditTRMProfileState extends State<EditTRMProfile> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noOfTrmsController = TextEditingController(text: "1");
  final TextEditingController _timePerTrmController = TextEditingController(text: "1.0");
  final TextEditingController _delayController = TextEditingController(text: "0.0");
  
  bool _isEditing = false;
  String _currentId = "0";

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!.isNotEmpty && widget.global.rowSelected.isNotEmpty) {
      _isEditing = true;
      _populateData(widget.initialData!);
    } else if (widget.global.rowSelected.isNotEmpty) {
      _isEditing = true;
      _fetchData();
    }
  }

  void _populateData(List<String> data) {
    if (data.isEmpty) return;
    int offset = 0;
    if (data.length == 5) { // With ID
      _currentId = data[0];
      offset = 1;
    } else if (data.length == 4) { // Without ID (from _fetchData)
      offset = 0;
    }
    
    if (data.length > offset) _nameController.text = data[offset] == "NULL" ? "" : data[offset];
    if (data.length > offset + 1) _noOfTrmsController.text = data[offset + 1] == "NULL" ? "" : data[offset + 1];
    if (data.length > offset + 2) _timePerTrmController.text = data[offset + 2] == "NULL" ? "" : data[offset + 2];
    if (data.length > offset + 3) _delayController.text = data[offset + 3] == "NULL" ? "" : data[offset + 3];
  }

  Future<void> _fetchData() async {
    try {
      RowDisplayRequest req = RowDisplayRequest();
      req.id = widget.global.clientID;
      req.tableName = getTableName(widget.global.tableSelected);
      req.primaryKey = widget.global.rowSelected; // For TRMProfile, rowSelected should be the Name

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8085/getRows'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(req.toJSON()),
      );

      if (response.statusCode == 200) {
        var temp = RowDisplayDetails.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        if (temp.ok && temp.values.isNotEmpty) {
          _populateData(temp.values);
          if (mounted) setState(() {});
        } else {
          showMessage(temp.message, true);
        }
      }
    } catch (e) {
      showMessage("Error connecting to server", true);
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
               _isEditing ? "Edit TRM Profile" : "Create TRM Profile", 
               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
             ),
          ),
          
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildField(_nameController, "Profile Name", "e.g. TRMP1"),
                    _buildField(_noOfTrmsController, "Number of TRMs", "e.g. 4", isNumber: true),
                    _buildField(_timePerTrmController, "Time Per TRM (Secs)", "e.g. 1.0", isNumber: true),
                    _buildField(_delayController, "Delay Before First Read (Secs)", "e.g. 0.0", isNumber: true),
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
                 mainAxisSize: MainAxisSize.max,
                 children: [
                   Expanded(
                     child: OutlinedButton(
                       onPressed: widget.callback,
                       style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                       child: const Text("Cancel"),
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: FilledButton.icon(
                       onPressed: _handleSave,
                       icon: Icon(_isEditing ? Icons.save : Icons.add, size: 20),
                       label: Text(_isEditing ? "Save Changes" : "Create"),
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

  Widget _buildField(TextEditingController controller, String label, String hint, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.withOpacity(0.04),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      ),
    );
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Construct values array corresponding exactly to TRMProfile Update/Insert expectation (NO ID).
    // [Name, NoOfTRMs, TimePerTRMInSecs, DelayBeforeFirstReadInSecs]
    List<String> values = [
      _nameController.text, // Index 0
      _noOfTrmsController.text, // Index 1
      _timePerTrmController.text, // Index 2
      _delayController.text // Index 3
    ];

    String clientID = widget.global.clientID;
    String tableName = getTableName(widget.global.tableSelected);
    
    // Pass the Name field as primary key for updates! (Values[1])
    bool ok;
    if (_isEditing) {
       ok = await sendUpdateRequest(clientID, tableName, values, primaryKey: widget.global.rowSelected);
    } else {
       ok = await sendAddRequest(clientID, tableName, values);
    }

    if (ok) {
      widget.callback();
    }
  }
}
