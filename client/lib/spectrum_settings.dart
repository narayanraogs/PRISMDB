import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/custom_dropdown.dart';
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class SpectrumSettings extends StatefulWidget {
  final Global global;
  final VoidCallback callback;

  const SpectrumSettings(this.global, this.callback, {super.key});

  @override
  State<SpectrumSettings> createState() => StateSpectrumSettings();
}

class StateSpectrumSettings extends State<SpectrumSettings> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _centreFrequencyController = TextEditingController();
  FrequencyDropDownMenu centerDDMenu = FrequencyDropDownMenu((value) {});
  String centerFreqResolution = 'Hz';
  TextEditingController _spanController = TextEditingController();
  FrequencyDropDownMenu spanDDMenu = FrequencyDropDownMenu((value) {});
  String spanFreqResolution = 'Hz';
  bool _suggest = false;
  TextEditingController _rbwController = TextEditingController();
  TextEditingController _vbwController = TextEditingController();

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
        Uri.parse('http://127.0.0.1:8085/getRows'),
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
          _centreFrequencyController.text = temp.values[1];
          _spanController.text = temp.values[2];
          _suggest = false;
          _vbwController.text = temp.values[3];
          _rbwController.text = temp.values[4];
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

  void setCenterFreqResolution(String value) {
    centerFreqResolution = value;
  }

  void setSpanFreqResolution(String value) {
    spanFreqResolution = value;
  }

  @override
  void initState() {
    super.initState();
    centerDDMenu = FrequencyDropDownMenu(setCenterFreqResolution);
    spanDDMenu = FrequencyDropDownMenu(setSpanFreqResolution);
    sendRequest();
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
              label: Text(isNew ? "Create Profile" : "Save Changes"),
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
      label: "Spectrum Profile Name",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Profile name cannot be empty";
        }
        return null;
      },
    ));

    centerDDMenu = FrequencyDropDownMenu(
      setCenterFreqResolution,
      key: Key(centerFreqResolution),
      selected: centerFreqResolution,
    );
    // centerDDMenu.setFrequency(centerFreqResolution);

    children.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildTextField(
            controller: _centreFrequencyController,
            label: "Center Frequency",
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "Required";
              if (double.tryParse(value) == null) return "Must be a number";
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: centerDDMenu,
        ),
      ],
    ));

    spanDDMenu = FrequencyDropDownMenu(
      setSpanFreqResolution,
      key: Key(spanFreqResolution),
      selected: spanFreqResolution,
    );
    // spanDDMenu.setFrequency(spanFreqResolution);

    children.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildTextField(
            controller: _spanController,
            label: "Span",
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "Required";
              if (double.tryParse(value) == null) return "Must be a number";
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: spanDDMenu,
        ),
      ],
    ));

    children.add(Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: CheckboxListTile(
          value: _suggest,
          onChanged: (value) {
            _suggest = value ?? false;
            setState(() {});
          },
          title: const Text("Suggest RBW and VBW?"),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ));

    if (!_suggest) {
      children.add(_buildTextField(
        controller: _rbwController,
        label: "RBW",
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Required";
          if (double.tryParse(value) == null) return "Must be a number";
          return null;
        },
      ));

      children.add(_buildTextField(
        controller: _vbwController,
        label: "VBW",
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Required";
          if (double.tryParse(value) == null) return "Must be a number";
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
    var centFreq =
        getFrequency(_centreFrequencyController.text, centerFreqResolution);
    values.add('$centFreq');
    var span = getFrequency(_spanController.text, spanFreqResolution);
    values.add('$span');
    var rbw = 0.0;
    try {
      rbw = double.parse(_rbwController.text);
    } catch (e) {
      rbw = 0.0;
    }
    values.add('$rbw');
    var vbw = 0.0;
    try {
      vbw = double.parse(_vbwController.text);
    } catch (e) {
      vbw = 0.0;
    }
    values.add('$vbw');
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
               widget.global.rowSelected.isEmpty ? "Create Spectrum Profile" : "Edit Spectrum Profile", 
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
