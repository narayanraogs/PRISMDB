import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/custom_dropdown.dart';
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class SpecTxHarmonics extends StatefulWidget {
  final Global global;
  final VoidCallback callback;

  const SpecTxHarmonics(this.global, this.callback, {super.key});

  @override
  State<SpecTxHarmonics> createState() => StateSpecTxHarmonics();
}

class StateSpecTxHarmonics extends State<SpecTxHarmonics> {
  final _formKey = GlobalKey<FormState>();
  List<String> _txNames = [];
  String _txName = '';
  final List<String> _harmonicsTypes = ['Harmonic', 'SubHarmonic'];
  String _harmonicsType = 'Harmonic';
  TextEditingController _nameController = TextEditingController();
  TextEditingController _freqController = TextEditingController();
  TextEditingController _lossController = TextEditingController();
  String freqResolution = 'Hz';
  FrequencyDropDownMenu frequencyDropDown = FrequencyDropDownMenu((value) {});

  void setFreqResolution(String value) {
    freqResolution = value;
  }

  void sendRequest() async {
    ValueRequest txReq = ValueRequest();
    txReq.id = widget.global.clientID;
    txReq.key = "TxNames";
    final txResp = await http.post(
      Uri.parse('http://127.0.0.1:8085/getValues'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(txReq.toJSON()),
    );
    if (txResp.statusCode == 200) {
      var temp = ValueResponse.fromJson(
          jsonDecode(txResp.body) as Map<String, dynamic>);
      if (temp.ok) {
        _txNames = [];
        _txNames.addAll(temp.values);
        _txName = _txNames.first;
      } else {
        showMessage(temp.message, true);
        return;
      }
    } else {
      showMessage("Server Returned Negative ACK", true);
      return;
    }
    if (widget.global.rowSelected == '') {
      setState(() {});
      return;
    }
    RowDisplayRequest req = RowDisplayRequest();
    req.id = widget.global.clientID;
    var tableName = getTableName(widget.global.tableSelected);
    req.tableName = tableName;
    req.primaryKey = widget.global.rowSelected;
    try {
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
          _txName = temp.values[0];
          _harmonicsType = temp.values[1];
          _nameController.text = temp.values[2];
          _freqController.text = temp.values[3];
          freqResolution = 'Hz';
          _lossController.text = temp.values[4];
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
    frequencyDropDown = FrequencyDropDownMenu(setFreqResolution);
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
              label: Text(isNew ? "Create Harmonic Spec" : "Save Changes"),
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
      child: getTxNameDropdown(),
    ));

    children.add(Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: getHarmonicTypeDropDown(),
    ));

    children.add(_buildTextField(
      controller: _nameController,
      label: "Harmonics Name",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Harmonics name cannot be empty";
        }
        return null;
      },
    ));

    frequencyDropDown = FrequencyDropDownMenu(
      setFreqResolution,
      key: Key(freqResolution),
      selected: freqResolution,
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
      controller: _lossController,
      label: "Total Loss from SA",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Loss cannot be empty";
        }
        if (double.tryParse(value) == null) {
          return "Must be a number";
        }
        return null;
      },
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
    values.add(_txName);
    values.add(_harmonicsType);
    values.add(_nameController.text);
    var freq = getFrequency(_freqController.text, freqResolution);
    values.add('$freq');
    var loss = 0.0;
    try {
      loss = double.parse(_lossController.text);
    } catch (e) {
      loss = 0.0;
    }
    values.add('$loss');

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
               widget.global.rowSelected.isEmpty ? "Create New Harmonic Spec" : "Edit Harmonic Spec", 
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

  DropdownButtonFormField<String> getTxNameDropdown() {
    List<DropdownMenuItem<String>> entries = [];
    for (String txName in _txNames) {
      var item = DropdownMenuItem<String>(
        value: txName,
        child: Text(txName),
      );
      entries.add(item);
    }
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: _txName.isEmpty && _txNames.isNotEmpty ? _txNames.first : _txName,
      decoration: InputDecoration(
        labelText: "Transmitter Name",
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (String? value) {
        _txName = value ?? (_txNames.isNotEmpty ? _txNames.first : '');
        setState(() {});
      },
    );
  }

  DropdownButtonFormField<String> getHarmonicTypeDropDown() {
    List<DropdownMenuItem<String>> entries = [];
    for (String harm in _harmonicsTypes) {
      var item = DropdownMenuItem<String>(
        value: harm,
        child: Text(harm),
      );
      entries.add(item);
    }
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: _harmonicsType,
      decoration: InputDecoration(
        labelText: "Harmonic Type",
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (String? value) {
        _harmonicsType = value ?? _harmonicsTypes.first;
        setState(() {});
      },
    );
  }
}
