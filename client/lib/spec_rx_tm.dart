import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class SpecRxTM extends StatefulWidget {
  final Global global;
  final VoidCallback callback;
  final List<String>? initialData;

  const SpecRxTM(this.global, this.callback, {this.initialData, super.key});

  @override
  State<SpecRxTM> createState() => StateSpecRxTM();
}

class StateSpecRxTM extends State<SpecRxTM> {
  final _formKey = GlobalKey<FormState>();
  List<String> _rxNames = [];
  String _rxName = '';
  TextEditingController _lsMnemonicController = TextEditingController();
  TextEditingController _lsValueController = TextEditingController();
  TextEditingController _blsMnemonicController = TextEditingController();
  TextEditingController _blsValueController = TextEditingController();
  TextEditingController _agcMnemonicController = TextEditingController();
  TextEditingController _ccMnemonicController = TextEditingController();
  TextEditingController _loopMnemonicController = TextEditingController();
  TextEditingController _testCmdSetController = TextEditingController();
  TextEditingController _testCmdResetController = TextEditingController();
  String _modulation = "PM";

  void sendRequest() async {
    ValueRequest txReq = ValueRequest();
    txReq.id = widget.global.clientID;
    txReq.key = "RxNames";
    final txResp = await http.post(
      Uri.parse('${Uri.base.origin}/getValues'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(txReq.toJSON()),
    );
    if (txResp.statusCode == 200) {
      var temp = ValueResponse.fromJson(
          jsonDecode(txResp.body) as Map<String, dynamic>);
      if (temp.ok) {
        _rxNames = [];
        _rxNames.addAll(temp.values);
        if (_rxNames.isNotEmpty && _rxName.isEmpty) {
          _rxName = _rxNames.first;
          updateModIndexRequest(_rxName);
        }
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
          _rxName = temp.values[0];
          _lsMnemonicController.text = temp.values[1];
          _lsValueController.text = temp.values[2];
          _blsMnemonicController.text = temp.values[3];
          _blsValueController.text = temp.values[4];
          _agcMnemonicController.text = temp.values[5];
          _ccMnemonicController.text = temp.values[6];
          _loopMnemonicController.text = temp.values[7];
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
    // Also fetch RxNames if they are not yet loaded
    if (_rxNames.isEmpty) {
      _fetchRxNames();
    }
  }

  void _fetchRxNames() async {
    ValueRequest txReq = ValueRequest();
    txReq.id = widget.global.clientID;
    txReq.key = "RxNames";
    final txResp = await http.post(
      Uri.parse('${Uri.base.origin}/getValues'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(txReq.toJSON()),
    );
    if (txResp.statusCode == 200) {
      var temp = ValueResponse.fromJson(jsonDecode(txResp.body) as Map<String, dynamic>);
      if (temp.ok) {
        setState(() {
          _rxNames = temp.values;
          if (_rxName.isEmpty && _rxNames.isNotEmpty) {
            _rxName = _rxNames.first;
            updateModIndexRequest(_rxName);
          }
        });
      }
    }
  }

  void _populateFromInitialData() {
    var data = widget.initialData!;
    // Schema: [RxName, LockStatusMnemonic, LockStatusValue, BSLockStatusMnemonic, BSLockStatusValue, AGCMnemonic, LoopStressMnemonic, CommandCounterMnemonic, TestCommandSet, TestCommandReset]
    if (data.isNotEmpty) _rxName = data[0];
    if (data.length > 1) _lsMnemonicController.text = data[1];
    if (data.length > 2) _lsValueController.text = data[2];
    if (data.length > 3) _blsMnemonicController.text = data[3];
    if (data.length > 4) _blsValueController.text = data[4];
    if (data.length > 5) _agcMnemonicController.text = data[5];
    if (data.length > 6) _loopMnemonicController.text = data[6];
    if (data.length > 7) _ccMnemonicController.text = data[7];
    if (data.length > 8) _testCmdSetController.text = data[8];
    if (data.length > 9) _testCmdResetController.text = data[9];
    // Mod index is triggered by rxName change
    updateModIndexRequest(_rxName);
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

    children.add(Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: getRxNameDropdown(),
    ));

    children.add(_buildTextField(
      controller: _lsMnemonicController,
      label: "Lock Status Mnemonic",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Required";
        }
        return null;
      },
    ));

    children.add(_buildTextField(
      controller: _lsValueController,
      label: "Lock Status Value",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Required";
        }
        return null;
      },
    ));

    children.add(_buildTextField(
      controller: _blsMnemonicController,
      label: "BitSync Lock Status Mnemonic",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Required";
        }
        return null;
      },
    ));

    children.add(_buildTextField(
      controller: _blsValueController,
      label: "BitSync Lock Status Value",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Required";
        }
        return null;
      },
    ));

    children.add(_buildTextField(
      controller: _agcMnemonicController,
      label: "AGC Mnemonic",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Required";
        }
        return null;
      },
    ));

    children.add(_buildTextField(
      controller: _ccMnemonicController,
      label: "Command Counter Mnemonic",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Required";
        }
        return null;
      },
    ));

    children.add(_buildTextField(
      controller: _testCmdSetController,
      label: "Test Command Set",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Required";
        }
        return null;
      },
    ));

    children.add(_buildTextField(
      controller: _testCmdResetController,
      label: "Test Command Reset",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Required";
        }
        return null;
      },
    ));

    if (_modulation == 'PM') {
      children.add(_buildTextField(
        controller: _loopMnemonicController,
        label: "Loop Stress Mnemonic",
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Required";
          }
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
    values
      ..add(_rxName)
      ..add(_lsMnemonicController.text)
      ..add(_lsValueController.text)
      ..add(_blsMnemonicController.text)
      ..add(_blsValueController.text)
      ..add(_agcMnemonicController.text)
      ..add(_loopMnemonicController.text)
      ..add(_ccMnemonicController.text)
      ..add(_testCmdSetController.text)
      ..add(_testCmdResetController.text);
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
               widget.global.rowSelected.isEmpty ? "Create New Receiver TM/TC" : "Edit Receiver TM/TC", 
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

  DropdownButtonFormField<String> getRxNameDropdown() {
    List<DropdownMenuItem<String>> entries = [];
    for (String txName in _rxNames) {
      var item = DropdownMenuItem<String>(
        value: txName,
        child: Text(txName),
      );
      entries.add(item);
    }
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: _rxName.isEmpty && _rxNames.isNotEmpty ? _rxNames.first : _rxName,
      decoration: InputDecoration(
        labelText: "Receiver Name",
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (String? value) {
        _rxName = value ?? (_rxNames.isNotEmpty ? _rxNames.first : '');
        updateModIndexRequest(_rxName);
        setState(() {});
      },
    );
  }

  void updateModIndexRequest(String rxName) async {
    ValueRequest txReq = ValueRequest();
    txReq.id = widget.global.clientID;
    txReq.key = "RxModulation:::$rxName";
    final txResp = await http.post(
      Uri.parse('${Uri.base.origin}/getSingleValue'),
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
