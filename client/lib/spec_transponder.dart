import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class SpecTransponder extends StatefulWidget {
  final Global global;
  final VoidCallback callback;
  final List<String>? initialData;

  const SpecTransponder(this.global, this.callback, {this.initialData, super.key});

  @override
  State<SpecTransponder> createState() => StateSpecTransponder();
}

class StateSpecTransponder extends State<SpecTransponder> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  
  String _rxName = '';
  String _txName = '';
  List<String> _rxNames = [];
  List<String> _txNames = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData().then((_) {
      if (widget.initialData != null && widget.initialData!.isNotEmpty && widget.global.rowSelected.isNotEmpty) {
        _populateFromInitialData();
      }
    });
  }

  Future<void> _fetchDropdownData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch Tx Names
      ValueRequest txReq = ValueRequest()..id = widget.global.clientID..key = "TxNames";
      final txResp = await http.post(
        Uri.parse('http://127.0.0.1:8085/getValues'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(txReq.toJSON()),
      );
      
      if (txResp.statusCode == 200) {
        var temp = ValueResponse.fromJson(jsonDecode(txResp.body));
        if (temp.ok) {
          _txNames = temp.values;
          if (_txNames.isNotEmpty) _txName = _txNames.first;
        }
      }

      // Fetch Rx Names
      ValueRequest rxReq = ValueRequest()..id = widget.global.clientID..key = "RxNames";
      final rxResp = await http.post(
        Uri.parse('http://127.0.0.1:8085/getValues'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(rxReq.toJSON()),
      );

      if (rxResp.statusCode == 200) {
        var temp = ValueResponse.fromJson(jsonDecode(rxResp.body));
        if (temp.ok) {
          _rxNames = temp.values;
          if (_rxNames.isNotEmpty) _rxName = _rxNames.first;
        }
      }
    } catch (e) {
      debugPrint("Dropdown fetch error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateFromInitialData() {
    var data = widget.initialData!;
    // Server Schema: [TpName, RxName, TxName]
    
    if (data.isNotEmpty) _nameController.text = data[0];
    
    if (data.length > 1) {
      if (_rxNames.contains(data[1])) _rxName = data[1];
    }
    
    if (data.length > 2) {
      if (_txNames.contains(data[2])) _txName = data[2];
    }
    
    setState(() {});
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
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _getChildren(),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => widget.callback(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _isLoading ? null : () => update(widget.initialData != null),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(widget.initialData == null ? "Insert" : "Save Changes"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getChildren() {
    return [
      _buildTextField(
        controller: _nameController,
        label: "Transponder Name",
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
      
      const Text("Receiver Name", style: TextStyle(fontSize: 14, color: Colors.grey)),
      const SizedBox(height: 8),
      _buildDropdown(
        value: _rxName,
        items: _rxNames,
        onChanged: (val) => setState(() => _rxName = val!),
      ),
      const SizedBox(height: 20),

      const Text("Transmitter Name", style: TextStyle(fontSize: 14, color: Colors.grey)),
      const SizedBox(height: 8),
      _buildDropdown(
        value: _txName,
        items: _txNames,
        onChanged: (val) => setState(() => _txName = val!),
      ),
    ];
  }

  Widget _buildTextField({required TextEditingController controller, required String label, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.withOpacity(0.04),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required void Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : (items.isNotEmpty ? items.first : null),
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  void update(bool edit) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    var clientID = widget.global.clientID;
    var tableName = getTableName(widget.global.tableSelected);
    List<String> values = [
      "0", // ID Placeholder
      _nameController.text,
      _rxName,
      _txName,
    ];

    bool ok = false;
    if (edit) {
      ok = await sendUpdateRequest(clientID, tableName, values, primaryKey: widget.global.rowSelected);
    } else {
      ok = await sendAddRequest(clientID, tableName, values);
    }

    if (ok) {
      widget.callback();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save transponder"), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }
}
