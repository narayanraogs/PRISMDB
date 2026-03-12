import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/custom_dropdown.dart';
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class SpecTxSubcarriers extends StatefulWidget {
  final Global global;
  final VoidCallback callback;

  const SpecTxSubcarriers(this.global, this.callback, {super.key});

  @override
  State<SpecTxSubcarriers> createState() => StateSpecTxSubcarriers();
}

class StateSpecTxSubcarriers extends State<SpecTxSubcarriers> {
  final _formKey = GlobalKey<FormState>();
  List<String> _txNames = [];
  String _txName = '';
  TextEditingController _nameController = TextEditingController();
  TextEditingController _freqController = TextEditingController();
  TextEditingController _modIndexController = TextEditingController();
  TextEditingController _modIndexDeviationController = TextEditingController();
  final List<String> _alwaysPresentStatus = ['No', 'Yes'];
  String _alwaysPresent = 'Yes';
  TextEditingController _peakFreqDeviationController = TextEditingController();
  String freqResolution = 'Hz';
  FrequencyDropDownMenu frequencyDropDown = FrequencyDropDownMenu((value) {});
  String _freqDeviationResolution = 'Hz';
  String _modulation = "PM";
  FrequencyDropDownMenu frequencyDeviationDropDown =
      FrequencyDropDownMenu((value) {});

  void setFreqResolution(String value) {
    freqResolution = value;
  }

  void setFreqDeviationResolution(String value) {
    _freqDeviationResolution = value;
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
        updateModIndexRequest(_txName);
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
          _nameController.text = temp.values[1];
          _freqController.text = temp.values[2];
          freqResolution = 'Hz';
          _modIndexController.text = temp.values[3];
          _modIndexDeviationController.text = temp.values[4];
          _alwaysPresent = temp.values[5];
          _peakFreqDeviationController.text = temp.values[6];
          _freqDeviationResolution = 'Hz';
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
    frequencyDeviationDropDown =
        FrequencyDropDownMenu(setFreqDeviationResolution);
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
              label: Text(isNew ? "Create Subcarrier" : "Save Changes"),
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

    children.add(_buildTextField(
      controller: _nameController,
      label: "Sub Carrier Name",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Sub Carrier name cannot be empty";
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

    if (_modulation == 'PM') {
      children.add(_buildTextField(
        controller: _modIndexController,
        label: "Mod Index",
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Required";
          if (double.tryParse(value) == null) return "Must be a number";
          return null;
        },
      ));

      children.add(_buildTextField(
        controller: _modIndexDeviationController,
        label: "Mod Index Deviation",
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Required";
          if (double.tryParse(value) == null) return "Must be a number";
          return null;
        },
      ));

      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: getAlwaysPresent(),
      ));
    }

    if (_modulation == "FSK") {
      frequencyDeviationDropDown = FrequencyDropDownMenu(
        setFreqDeviationResolution,
        key: Key(_freqDeviationResolution),
        selected: _freqDeviationResolution,
      );

      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _buildTextField(
              controller: _peakFreqDeviationController,
              label: "Peak Frequency Deviation",
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
            child: frequencyDeviationDropDown,
          ),
        ],
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
    values.add(_txName);
    values.add(_nameController.text);
    var freq = getFrequency(_freqController.text, freqResolution);
    values.add('$freq');
    var mi = 0.0;
    try {
      mi = double.parse(_modIndexController.text);
    } catch (e) {
      mi = 0.0;
    }
    values.add('$mi');

    var miDev = 0.0;
    try {
      miDev = double.parse(_modIndexDeviationController.text);
    } catch (e) {
      miDev = 0.0;
    }
    values.add('$miDev');
    values.add(_alwaysPresent);
    var pk = 0.0;
    try {
      pk = double.parse(_peakFreqDeviationController.text);
    } catch (e) {
      pk = 0.0;
    }
    values.add('$pk');
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
               widget.global.rowSelected.isEmpty ? "Create New Subcarrier" : "Edit Subcarrier", 
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
        updateModIndexRequest(_txName);
        setState(() {});
      },
    );
  }

  DropdownButtonFormField<String> getAlwaysPresent() {
    List<DropdownMenuItem<String>> entries = [];
    for (String al in _alwaysPresentStatus) {
      var item = DropdownMenuItem<String>(
        value: al,
        child: Text(al),
      );
      entries.add(item);
    }
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: _alwaysPresent,
      decoration: InputDecoration(
        labelText: "Always Present",
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (String? value) {
        _alwaysPresent = value ?? _alwaysPresentStatus.first;
        setState(() {});
      },
    );
  }

  void updateModIndexRequest(String txName) async {
    ValueRequest txReq = ValueRequest();
    txReq.id = widget.global.clientID;
    txReq.key = "TxModulation:::$txName";
    final txResp = await http.post(
      Uri.parse('http://127.0.0.1:8085/getSingleValue'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(txReq.toJSON()),
    );
    if (txResp.statusCode == 200) {
      var temp = SingleValueResponse.fromJson(
          jsonDecode(txResp.body) as Map<String, dynamic>);
      if (temp.ok) {
        _modulation = temp.value;
        setState(() {});
      } else {
        showMessage(temp.message, true);
        return;
      }
    } else {
      showMessage("Server Returned Negative ACK", true);
      return;
    }
  }
}
