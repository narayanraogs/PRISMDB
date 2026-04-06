import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class AddTestPhase extends StatefulWidget {
  final Global global;
  final VoidCallback callback;
  final List<String>? initialData;

  const AddTestPhase(this.global, this.callback, {this.initialData, super.key});

  @override
  State<AddTestPhase> createState() => StateAddTestPhase();
}

class StateAddTestPhase extends State<AddTestPhase> {
  final _formKey = GlobalKey<FormState>();
  
  // Name Fields
  String _selectedName = 'Pre-T&E';
  final TextEditingController _customNameController = TextEditingController();
  final List<String> _predefinedNames = [
    "Pre-T&E", "Dis-Assembled", "Assembled", "Pre-TVAC", 
    "Cold-Soak", "Hot-Soak", "Short-Cold", "Short-Hot", 
    "Post-TVAC", "Pre-Dynamics", "Post-Dynamics", 
    "Pre-Shipment", "SP1", "Custom"
  ];

  // Selected (Yes/No)
  String _selectedStatus = 'Yes';
  final List<String> _statusOptions = ['Yes', 'No'];

  bool _isEditing = false;
  String _currentId = "0";

  @override
  void initState() {
    super.initState();
    _isEditing = widget.global.rowSelected.isNotEmpty;
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _populateData(widget.initialData!);
    } else if (_isEditing) {
      sendRequest();
    }
  }

  void _populateData(List<String> data) {
    if (data.isEmpty) return;
    
    // Data Structure from Table View (Reflection order):
    // [ID, Name, Date, Time, Selected]
    
    _currentId = data[0]; // ID
    
    // Name Logic
    String name = (data.length > 1) ? data[1] : "";
    if (_predefinedNames.contains(name)) {
      _selectedName = name;
    } else {
      _selectedName = "Custom";
      _customNameController.text = name;
    }

    // Selected Logic (1 or 0 -> Yes or No)
    if (data.length > 4) {
      _selectedStatus = (data[4] == "1") ? "Yes" : "No";
    }
    
    setState(() {});
  }

  void sendRequest() async {
    RowDisplayRequest req = RowDisplayRequest();
    req.id = widget.global.clientID;
    req.tableName = "TestPhases"; // getTableName(widget.global.tableSelected);
    req.primaryKey = widget.global.rowSelected; // Name is PK
    
    try {
      final response = await http.post(
        Uri.parse('${Uri.base.origin}/getRows'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(req.toJSON()),
      );

      if (response.statusCode == 200) {
        var temp = RowDisplayDetails.fromJson(jsonDecode(response.body));
        if (temp.ok) {
           // Server returns [ID, Name, Date, Time, Selected] for TestPhases handler?
           // Actually, let's check RowHandlers `handleGetTestPhases`:
           // resp.Values = [ID, Name, Date, Time, Selected]
           _populateData(temp.values);
        } else {
          showMessage(temp.message, true);
        }
      } else {
        showMessage("Server Returned Negative ACK", true);
      }
    } catch (e) {
      debugPrint('$e');
      showMessage("Server Failed", true);
    }
  }

  @override
  Widget build(BuildContext context) {
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
             child: Text(
               _isEditing ? "Edit Test Phase" : "Create New Test Phase", 
               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
             ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildChildren(),
                ),
              ),
            ),
          ),
          
          Container(
             decoration: BoxDecoration(
               color: Colors.grey.shade50,
               border: Border(top: BorderSide(color: Colors.grey.shade200)),
             ),
             child: _buildButtons()
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChildren() {
    List<Widget> children = [];

    // Phase Name Dropdown
    children.add(const Text("Phase Name", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)));
    children.add(const SizedBox(height: 8));
    children.add(DropdownButtonFormField<String>(
      value: _selectedName,
      items: _predefinedNames.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedName = val);
      },
      decoration: _inputDecoration("Select Phase Name"),
    ));
    children.add(const SizedBox(height: 16));

    // Custom Name Field (if Custom selected)
    if (_selectedName == "Custom") {
      children.add(_buildTextField(
        controller: _customNameController,
        label: "Enter Custom Name",
        validator: (v) => (v == null || v.trim().isEmpty) ? "Name is required" : null,
      ));
    }

    // Selected Status (Yes/No)
    children.add(const Text("Selected", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)));
    children.add(const SizedBox(height: 8));
    children.add(DropdownButtonFormField<String>(
      value: _selectedStatus,
      items: _statusOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedStatus = val);
      },
      decoration: _inputDecoration("Is Selected?"),
    ));
    children.add(const SizedBox(height: 16));

    // Information about Date/Time
    children.add(Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.access_time, size: 20, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(child: Text(
            "Creation Date and Time will be automatically updated to the current time upon saving.",
            style: TextStyle(color: Colors.blue, fontSize: 13),
          )),
        ],
      ),
    ));

    return children;
  }

  Widget _buildButtons() {
    return Padding(
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
              icon: Icon(_isEditing ? Icons.save : Icons.add, size: 20),
              label: Text(_isEditing ? "Save Changes" : "Create Phase"),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSave() async {
    if (_formKey.currentState?.validate() != true) return;

    String finalName = (_selectedName == "Custom") ? _customNameController.text.trim() : _selectedName;
    String finalSelected = (_selectedStatus == "Yes") ? "1" : "0";
    
    // Generate Current Date and Time
    DateTime now = DateTime.now();
    // Default Go/SQL format usually: YYYY-MM-DD
    String dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    // Time format: HH:MM:SS
    String timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    List<String> values = [];
    if (_isEditing) {
      // Update: [ID, Name, Date, Time, Selected]
      values.add(_currentId);
      values.add(finalName);
      values.add(dateStr);
      values.add(timeStr);
      values.add(finalSelected);
      
      bool ok = await sendUpdateRequest(
        widget.global.clientID, 
        "TestPhases", 
        values, 
        primaryKey: widget.global.rowSelected // Old Name as PK
      );
      if (ok) {
        widget.callback();
      }
    } else {
      // Insert: [Name, Date, Time, Selected]
      values.add(finalName);
      values.add(dateStr);
      values.add(timeStr);
      values.add(finalSelected);
      
      bool ok = await sendAddRequest(widget.global.clientID, "TestPhases", values);
      if (ok) {
        widget.callback();
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    FormFieldValidator<String>? validator
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label),
        validator: validator,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.withOpacity(0.04),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
