import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/custom_dropdown.dart';
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class SpecTransponderRanging extends StatefulWidget {
  final Global global;
  final VoidCallback callback;
  final List<String>? initialData;

  const SpecTransponderRanging(this.global, this.callback, {this.initialData, super.key});

  @override
  State<SpecTransponderRanging> createState() => StateSpecTransponderRanging();
}

class StateSpecTransponderRanging extends State<SpecTransponderRanging> {
  final _formKey = GlobalKey<FormState>();
  List<String> _tpNames = [];
  String _tpName = '';
  TextEditingController _rangNameController = TextEditingController();
  TextEditingController _freqController = TextEditingController();
  TextEditingController _miToneRangingController = TextEditingController();
  TextEditingController _miToneCmdController = TextEditingController();
  TextEditingController _miCmdController = TextEditingController();
  TextEditingController _miToneDLController = TextEditingController();
  TextEditingController _miDevToneDLController = TextEditingController();
  List<String> _availableStates = ['Yes', 'No'];
  String _availableForCommanding = 'Yes';

  FrequencyDropDownMenu frequencyDropDown = FrequencyDropDownMenu((value) {});
  String _freqResolution = 'Hz';

  void setFreqResolution(String value) {
    _freqResolution = value;
  }

  void sendRequest() async {
    ValueRequest tpReq = ValueRequest();
    tpReq.id = widget.global.clientID;
    tpReq.key = "TPNames";
    final tpResp = await http.post(
      Uri.parse('${Uri.base.origin}/getValues'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(tpReq.toJSON()),
    );
    if (tpResp.statusCode == 200) {
      var temp = ValueResponse.fromJson(
          jsonDecode(tpResp.body) as Map<String, dynamic>);
      if (temp.ok) {
        _tpNames = [];
        _tpNames.addAll(temp.values);
        _tpName = _tpNames.first;
      } else {
        showMessage(temp.message, true);
        return;
      }
    } else {
      showMessage("Server Returned Negative ACK", true);
      return;
    }
    if (widget.global.rowSelected == '') {
      if (widget.initialData != null && widget.initialData!.isNotEmpty) {
        _populateFromInitialData();
      } else {
        setState(() {});
      }
      return;
    }
    RowDisplayRequest req = RowDisplayRequest();
    req.id = widget.global.clientID;
    var tableName = getTableName(widget.global.tableSelected);
    req.tableName = tableName;
    req.primaryKey = widget.global.rowSelected;
    try {
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
          _tpName = temp.values[0];
          _rangNameController.text = temp.values[1];
          _freqController.text = temp.values[2];
          _freqResolution = 'Hz';
          _miToneRangingController.text = temp.values[3];
          _miToneCmdController.text = temp.values[4];
          _miCmdController.text = temp.values[5];
          _miToneDLController.text = temp.values[6];
          _miDevToneDLController.text = temp.values[7];
          _availableForCommanding = temp.values[8];
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
    sendRequest();
  }

  void _populateFromInitialData() {
    var data = widget.initialData!;
    if (data.isNotEmpty && _tpNames.contains(data[0])) {
      _tpName = data[0];
    }
    if (data.length > 1) _rangNameController.text = data[1];
    if (data.length > 2) {
      _freqController.text = data[2];
      _freqResolution = 'Hz';
    }
    if (data.length > 3) _miToneRangingController.text = data[3];
    if (data.length > 4) _miToneCmdController.text = data[4];
    if (data.length > 5) _miCmdController.text = data[5];
    if (data.length > 6) _miToneDLController.text = data[6];
    if (data.length > 7) _miDevToneDLController.text = data[7];
    if (data.length > 8 && _availableStates.contains(data[8])) {
       _availableForCommanding = data[8];
    }
    setState(() {});
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
              label: Text(isNew ? "Create Ranging Spec" : "Save Changes"),
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

    children.add(Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: getTpNameDropdown(),
    ));

    children.add(_buildTextField(
      controller: _rangNameController,
      label: "Ranging Name",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Ranging Name cannot be empty";
        }
        return null;
      },
    ));

    frequencyDropDown = FrequencyDropDownMenu(
      setFreqResolution,
      key: Key(_freqResolution),
      selected: _freqResolution,
    );

    children.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildTextField(
            controller: _freqController,
            label: "Frequency",
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Frequency cannot be empty";
              }
              if (double.tryParse(value) == null) {
                return "Must be a number";
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: frequencyDropDown,
        ),
      ],
    ));

    children.add(_buildTextField(
      controller: _miToneRangingController,
      label: "Mod Index - Only Tone",
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "Required";
        if (double.tryParse(value) == null) return "Must be a number";
        return null;
      },
    ));

    children.add(_buildTextField(
      controller: _miToneCmdController,
      label: "Mod Index Tone - With Cmd",
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "Required";
        if (double.tryParse(value) == null) return "Must be a number";
        return null;
      },
    ));

    children.add(_buildTextField(
      controller: _miCmdController,
      label: "Mod Index Cmd",
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "Required";
        if (double.tryParse(value) == null) return "Must be a number";
        return null;
      },
    ));

    children.add(_buildTextField(
      controller: _miToneDLController,
      label: "Mod Index Tone - Downlink",
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "Required";
        if (double.tryParse(value) == null) return "Must be a number";
        return null;
      },
    ));

    children.add(_buildTextField(
      controller: _miDevToneDLController,
      label: "Mod Index Tone Deviation - Downlink",
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "Required";
        if (double.tryParse(value) == null) return "Must be a number";
        return null;
      },
    ));

    children.add(Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: getAvailableDropDown(),
    ));

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
    values
      ..add(_tpName)
      ..add(_rangNameController.text)
      ..add(getDouble('${getFrequency(_freqController.text, _freqResolution)}'))
      ..add(getDouble(_miToneRangingController.text))
      ..add(getDouble(_miToneCmdController.text))
      ..add(getDouble(_miCmdController.text))
      ..add(getDouble(_miToneDLController.text))
      ..add(getDouble(_miDevToneDLController.text))
      ..add(_availableForCommanding);
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
               widget.global.rowSelected.isEmpty ? "Create New Ranging Spec" : "Edit Ranging Spec", 
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

  DropdownButtonFormField<String> getTpNameDropdown() {
    List<DropdownMenuItem<String>> entries = [];
    for (String tpName in _tpNames) {
      var item = DropdownMenuItem<String>(
        value: tpName,
        child: Text(tpName),
      );
      entries.add(item);
    }
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: _tpName.isEmpty && _tpNames.isNotEmpty ? _tpNames.first : _tpName,
      decoration: InputDecoration(
        labelText: "Transponder Name",
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (String? value) {
        _tpName = value ?? (_tpNames.isNotEmpty ? _tpNames.first : '');
        setState(() {});
      },
    );
  }

  DropdownButtonFormField<String> getAvailableDropDown() {
    List<DropdownMenuItem<String>> entries = [];
    for (String always in _availableStates) {
      var item = DropdownMenuItem<String>(
        value: always,
        child: Text(always),
      );
      entries.add(item);
    }
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: _availableForCommanding,
      decoration: InputDecoration(
        labelText: "Available for Commanding?",
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (String? value) {
        _availableForCommanding = value ?? _availableStates.first;
        setState(() {});
      },
    );
  }
}
