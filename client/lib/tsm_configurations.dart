import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class TsmConfigurations extends StatefulWidget {
  final Global global;
  final VoidCallback callback;
  final List<String>? initialData;

  const TsmConfigurations(this.global, this.callback, {this.initialData, super.key});

  @override
  State<TsmConfigurations> createState() => StateTsmConfigurations();
}

class StateTsmConfigurations extends State<TsmConfigurations> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _uplinkToSCController = TextEditingController();
  TextEditingController _includePadController = TextEditingController();
  TextEditingController _excludePadController = TextEditingController();
  TextEditingController _uplinkToSAController = TextEditingController();
  TextEditingController _uplinkToPMController = TextEditingController();
  TextEditingController _terminateUplinkController = TextEditingController();
  TextEditingController _downlinkToSAController = TextEditingController();
  TextEditingController _downlinkToPMController = TextEditingController();
  TextEditingController _attenuationController = TextEditingController();
  bool _uplink = false;
  bool _downlink = false;

  void sendRequest() async {
    try {
      RowDisplayRequest req = RowDisplayRequest();
      req.id = widget.global.clientID;
      var tableName = getTableName(widget.global.tableSelected);
      req.tableName = tableName;
      req.primaryKey = widget.global.rowSelected;

      if (widget.global.rowSelected == '') {
        setState(() {});
        return;
      }

      final response = await http.post(
        Uri.parse('${Uri.base.origin}/getRows'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(req.toJSON()),
      );

      if (response.statusCode == 200) {
        var temp = RowDisplayDetails.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
        if (temp.ok) {
          _nameController.text = temp.values[0];
          _uplinkToSCController.text = temp.values[1];
          _includePadController.text = temp.values[2];
          _excludePadController.text = temp.values[3];
          _uplinkToSAController.text = temp.values[4];
          _uplinkToPMController.text = temp.values[5];
          _terminateUplinkController.text = temp.values[6];
          _downlinkToSAController.text = temp.values[7];
          _downlinkToPMController.text = temp.values[8];
          _attenuationController.text = temp.values[9];

          // Determine Checkbox states based on data presence
          _updateCheckboxStates();
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
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!.isNotEmpty && widget.global.rowSelected.isNotEmpty) {
      _populateFromInitialData();
    } else {
      sendRequest();
    }
  }

  void _populateFromInitialData() {
    var data = widget.initialData!;
    // Table Data (Reflection) vs Row Handler manual mapping offset
    // ID is index 0 in Table Data. Name is index 1.
    if (data.length > 1) _nameController.text = data[1];
    if (data.length > 2) _uplinkToSCController.text = data[2];
    if (data.length > 3) _includePadController.text = data[3];
    if (data.length > 4) _excludePadController.text = data[4];
    if (data.length > 5) _uplinkToSAController.text = data[5];
    if (data.length > 6) _uplinkToPMController.text = data[6];
    if (data.length > 7) _terminateUplinkController.text = data[7];
    if (data.length > 8) _downlinkToSAController.text = data[8];
    if (data.length > 9) _downlinkToPMController.text = data[9];
    if (data.length > 10) _attenuationController.text = data[10];

    _updateCheckboxStates();
    setState(() {});
  }

  void _updateCheckboxStates() {
    if (_uplinkToSCController.text.isNotEmpty || _uplinkToSAController.text.isNotEmpty || _uplinkToPMController.text.isNotEmpty) {
      _uplink = true;
    }
    if (_downlinkToSAController.text.isNotEmpty || _downlinkToPMController.text.isNotEmpty) {
      _downlink = true;
    }
  }

  Widget getButton(BuildContext context) {
    bool isNew = widget.global.rowSelected.trim().isEmpty;
    
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
                if (!_formKey.currentState!.validate()) {
                  showMessage("Please check the inputs", true);
                  return;
                }
                update(!isNew);
              },
              icon: Icon(isNew ? Icons.add : Icons.save, size: 20),
              label: Text(isNew ? "Insert" : "Save Changes"),
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

  List<Widget> getChildren(BuildContext context) {
    List<Widget> children = [];

    children.add(_buildTextField(
      controller: _nameController,
      label: "TSM Configuration Name",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "TSM Configuration cannot be empty";
        }
        return null;
      },
    ));

    children.add(Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: CheckboxListTile(
                value: _uplink,
                title: const Text("Uplink"),
                onChanged: (value) {
                  _uplink = value ?? true;
                  setState(() {});
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                controlAffinity: ListTileControlAffinity.leading,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: CheckboxListTile(
                value: _downlink,
                title: const Text("Downlink"),
                onChanged: (value) {
                  _downlink = value ?? true;
                  setState(() {});
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                controlAffinity: ListTileControlAffinity.leading,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    ));

    if (_uplink) {
      children.add(const Padding(
        padding: EdgeInsets.only(bottom: 12.0),
        child: Text("Uplink Settings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
      ));

      children.add(_buildTextField(
        controller: _uplinkToSCController,
        label: "Uplink To Spacecraft",
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Required";
          return null;
        },
      ));

      children.add(_buildTextField(
        controller: _includePadController,
        label: "Include Pad",
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Required";
          return null;
        },
      ));

      children.add(_buildTextField(
        controller: _excludePadController,
        label: "Exclude Pad",
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Required";
          return null;
        },
      ));

      children.add(_buildTextField(
        controller: _uplinkToSAController,
        label: "Uplink to SA",
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Required";
          return null;
        },
      ));

      children.add(_buildTextField(
        controller: _uplinkToPMController,
        label: "Uplink to PM",
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Required";
          return null;
        },
      ));

      children.add(_buildTextField(
        controller: _terminateUplinkController,
        label: "Terminate Uplink",
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Required";
          return null;
        },
      ));

      children.add(_buildTextField(
        controller: _attenuationController,
        label: "Attenuation",
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Required";
          if (int.tryParse(value) == null) return "Must be an integer";
          return null;
        },
      ));
    }

    if (_downlink) {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 10.0, bottom: 12.0),
        child: Text("Downlink Settings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
      ));

      children.add(_buildTextField(
        controller: _downlinkToSAController,
        label: "Downlink to SA",
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Required";
          return null;
        },
      ));

      children.add(_buildTextField(
        controller: _downlinkToPMController,
        label: "Downlink to PM",
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Required";
          return null;
        },
      ));
    }
    return children;
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool readOnly = false,
    Color? fillColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: fillColor ?? Colors.grey.withOpacity(0.04),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  void update(bool edit) async {
    var clientID = widget.global.clientID;
    var tableName = getTableName(widget.global.tableSelected);
    List<String> values = [];
    values.add(_nameController.text);
    values.add(_uplinkToSCController.text);
    values.add(_includePadController.text);
    values.add(_excludePadController.text);
    values.add(_uplinkToSAController.text);
    values.add(_uplinkToPMController.text);
    values.add(_terminateUplinkController.text);
    values.add(_downlinkToSAController.text);
    values.add(_downlinkToPMController.text);
    values.add(_attenuationController.text);
    if (edit) {
      var ok = await sendUpdateRequest(clientID, tableName, values,
          primaryKey: widget.global.rowSelected);
      if (ok) {
        widget.global.subMode = SubModes.showTables;
        widget.callback();
      }
    } else {
      var ok = await sendAddRequest(clientID, tableName, values);
      if (ok) {
        widget.global.subMode = SubModes.showTables;
        widget.callback();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var children = getChildren(context);
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
             child: Text(
               widget.global.rowSelected.isEmpty ? "Create TSM Configuration" : "Edit TSM Configuration", 
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
                  children: children,
                ),
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
