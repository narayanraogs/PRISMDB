import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class Configurations extends StatefulWidget {
  final Global global;
  final VoidCallback callback;
  final List<String>? initialData;

  const Configurations(this.global, this.callback, {super.key, this.initialData});

  @override
  State<Configurations> createState() => StateConfigurations();
}

class StateConfigurations extends State<Configurations> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  final List<String> _configTypes = ['Rx', 'Tx', 'Tp', 'PL'];
  String _configType = 'Rx';
  List<String> _rxNames = [];
  String _rxName = '';
  List<String> _txNames = [];
  String _txName = '';
  List<String> _tpNames = [];
  String _tpName = '';
  List<String> _plNames = [];
  String _plName = '';
  List<String> _tsmNames = [];
  String _tsmName = '';
  final List<String> _ifms = ['1', '2'];
  String _ifm = '1';
  TextEditingController _ifController = TextEditingController();
  final List<String> _pmChannels = ['A', 'B'];
  String _pmChannel = 'A';
  final List<String> _progAttnOptions = ['Yes', 'No'];
  String _progAttnUsed = 'Yes';
  String _deviceProfileName = ''; // Hidden field to preserve DeviceProfileName

  void sendRequest() async {
    // 1. Fetch Dropdown Options
    await _fetchDropdownOptions();

    // 2. Populate Form Data
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _populateFromInitialData();
    } else if (widget.global.rowSelected.isNotEmpty) {
      await _fetchRowData();
    }
    
    // Trigger rebuild to show data
    if (mounted) setState(() {});
  }

  Future<void> _fetchDropdownOptions() async {
    // Fetch TxNames
    await _fetchValues("TxNames").then((values) {
        if (mounted) {
             _txNames = values;
             if (_txName.isEmpty && values.isNotEmpty) _txName = values.first;
        }
    });

    // Fetch RxNames
    await _fetchValues("RxNames").then((values) {
        if (mounted) {
            _rxNames = values;
            if (_rxName.isEmpty && values.isNotEmpty) _rxName = values.first;
        }
    });

    // Fetch TPNames
    await _fetchValues("TPNames").then((values) {
        if (mounted) {
            _tpNames = values;
            if (_tpName.isEmpty && values.isNotEmpty) _tpName = values.first;
        }
    });

    // Fetch PLNames
    await _fetchValues("PLNames").then((values) {
        if (mounted) {
            _plNames = values;
            if (_plName.isEmpty && values.isNotEmpty) _plName = values.first;
        }
    });
    // Fetch TSMConfigurations
    await _fetchValues("TSMConfigurations").then((values) {
        if (mounted) {
            _tsmNames = values;
            if (_tsmName.isEmpty && values.isNotEmpty) _tsmName = values.first;
        }
    });
  }

  Future<List<String>> _fetchValues(String key) async {
    try {
      ValueRequest req = ValueRequest();
      req.id = widget.global.clientID;
      req.key = key;
      final resp = await http.post(
        Uri.parse('${Uri.base.origin}/getValues'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(req.toJSON()),
      );
      if (resp.statusCode == 200) {
        var temp = ValueResponse.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
        if (temp.ok) return temp.values;
      }
    } catch (e) {
      debugPrint("Error fetching $key: $e");
    }
    return [];
  }

  void _populateFromInitialData() {
    List<String> data = widget.initialData!;
    // initialData comes from getTables (Struct Order in TableHandlers.go):
    // 0: ID
    // 1: ConfigName
    // 2: ConfigType
    // 3: RxName
    // 4: TxName
    // 5: TpName
    // 6: PayloadName (PMChannel)
    // 7: TSMConfigurationName
    // 8: CortexIFM
    // 9: IntermediateFrequency
    // 10: ProgrammableAttnUsed
    // 11: DeviceProfileName

    if (data.length >= 12) {
        // ID is at 0, skip it or use if needed
        _nameController.text = data[1];
        _configType = data[2];
        _rxName = data[3];
        _txName = data[4];
        _tpName = data[5];
        if (_configType == 'Pl' || _configType == 'PL') {
            _configType = 'PL'; // Normalize to PL
            _plName = data[6];
            _rxName = '';
            _txName = '';
            _tpName = '';
            _pmChannel = ''; // Used for Tx/Tp
        }
        
        _tsmName = data[7];
        _ifm = data[8];
        _ifController.text = data[9];
        _progAttnUsed = data[10];
        _deviceProfileName = data[11];
    }
  }

  Future<void> _fetchRowData() async {
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
        if (temp.ok && temp.values.length >= 11) {
           _nameController.text = temp.values[0];
           _configType = temp.values[1];
           _rxName = temp.values[2];
           _txName = temp.values[3];
           _tpName = temp.values[4];
           _tsmName = temp.values[5];
           _ifm = temp.values[6];
           _ifController.text = temp.values[7];
           if (_configType == 'Pl' || _configType == 'PL') {
               _configType = 'PL'; // Normalize to PL
               _plName = temp.values[8]; // PayloadName
               _rxName = '';
               _txName = '';
               _tpName = '';
               _pmChannel = '';
           }
           
           _deviceProfileName = temp.values[9];
           _progAttnUsed = temp.values[10];
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

  // ... (build methods) ...
  
  @override
  void initState() {
    super.initState();
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
              label: Text(isNew ? "Create Config" : "Save Changes"),
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
      label: "Configuration Name",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Configuration name cannot be empty";
        }
        return null;
      },
    ));

    children.add(Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: getConfigTypeDD(),
    ));

    if (_configType == 'Rx') {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: getRxNameDropdown(),
      ));
    }

    if (_configType == 'Tx') {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: getTxNameDropdown(),
      ));
    }

    if (_configType == 'Tp') {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: getTpNameDropdown(),
      ));
    }

    if (_configType == 'PL') {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: getPlNameDropdown(),
      ));
    }

    children.add(Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: getTSMNameDropdown(),
    ));

    if ((_configType == 'Rx') || (_configType == 'Tp')) {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: getCortexIFMDropdown(),
      ));

      children.add(_buildTextField(
        controller: _ifController,
        label: "Intermediate Frequency",
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Required";
          if (int.tryParse(value) == null) return "Must be an integer";
          return null;
        },
      ));

      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: getProgAttnDD(),
      ));
    }

    if ((_configType == 'Tx') || (_configType == 'Tp')) {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: getPMChannelDD(),
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
    values.add(_configType);
    switch (_configType) {
      case "Rx":
        values.add(_rxName);
        values.add('');
        values.add('');
      case "Tx":
        values.add('');
        values.add(_txName);
        values.add('');
      case "Tp":
        values.add('');
        values.add('');
        values.add(_tpName);
      case "PL":
        values.add('');
        values.add('');
        values.add('');
    }
    values.add(_tsmName);
    values.add(_ifm);
    var freq = 0.0;
    try {
      freq = double.parse(_ifController.text);
    } catch (e) {
      freq = 0.0;
    }
    values.add('$freq');
    
    // Index 8: PayloadName
    if (_configType == 'PL') {
        values.add(_plName);
    } else {
        values.add(_pmChannel); 
    }
    values.add(_deviceProfileName); // 9: DeviceProfileName
    values.add(_progAttnUsed); // 10: ProgAttnUsed
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
               widget.global.rowSelected.isEmpty ? "Create Configuration" : "Edit Configuration", 
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
      value: (_txNames.contains(_txName)) ? _txName : (_txNames.isNotEmpty ? _txNames.first : null),
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
      value: (_tpNames.contains(_tpName)) ? _tpName : (_tpNames.isNotEmpty ? _tpNames.first : null),
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

  DropdownButtonFormField<String> getPlNameDropdown() {
    List<DropdownMenuItem<String>> entries = [];
    for (String plName in _plNames) {
      var item = DropdownMenuItem<String>(
        value: plName,
        child: Text(plName),
      );
      entries.add(item);
    }
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: (_plNames.contains(_plName)) ? _plName : (_plNames.isNotEmpty ? _plNames.first : null),
      decoration: InputDecoration(
        labelText: "Payload Name",
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (String? value) {
        _plName = value ?? (_plNames.isNotEmpty ? _plNames.first : '');
        setState(() {});
      },
    );
  }

  DropdownButtonFormField<String> getTSMNameDropdown() {
    List<DropdownMenuItem<String>> entries = [];
    for (String tsm in _tsmNames) {
      var item = DropdownMenuItem<String>(
        value: tsm,
        child: Text(tsm),
      );
      entries.add(item);
    }
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: (_tsmNames.contains(_tsmName)) ? _tsmName : (_tsmNames.isNotEmpty ? _tsmNames.first : null),
      decoration: InputDecoration(
        labelText: "TSM Configuration Name",
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (String? value) {
        _tsmName = value ?? (_tsmNames.isNotEmpty ? _tsmNames.first : '');
        setState(() {});
      },
    );
  }

  DropdownButtonFormField<String> getCortexIFMDropdown() {
    List<DropdownMenuItem<String>> entries = [];
    for (String ifm in _ifms) {
      var item = DropdownMenuItem<String>(
        value: ifm,
        child: Text(ifm),
      );
      entries.add(item);
    }
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: _ifm,
      decoration: InputDecoration(
        labelText: "Cortex IFM",
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (String? value) {
        _ifm = value ?? _ifms.first;
        setState(() {});
      },
    );
  }

  DropdownButtonFormField<String> getProgAttnDD() {
    List<DropdownMenuItem<String>> entries = [];
    for (String opt in _progAttnOptions) {
      var item = DropdownMenuItem<String>(
        value: opt,
        child: Text(opt),
      );
      entries.add(item);
    }
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: (_progAttnOptions.contains(_progAttnUsed)) ? _progAttnUsed : (_progAttnOptions.isNotEmpty ? _progAttnOptions.first : null),
      decoration: InputDecoration(
        labelText: "Programmable Attn Used?",
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (String? value) {
        _progAttnUsed = value ?? _progAttnOptions.first;
        setState(() {});
      },
    );
  }

  DropdownButtonFormField<String> getPMChannelDD() {
    List<DropdownMenuItem<String>> entries = [];
    for (String pm in _pmChannels) {
      var item = DropdownMenuItem<String>(
        value: pm,
        child: Text(pm),
      );
      entries.add(item);
    }
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: (_pmChannels.contains(_pmChannel)) ? _pmChannel : (_pmChannels.isNotEmpty ? _pmChannels.first : null),
      decoration: InputDecoration(
        labelText: "Power Meter Channel",
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (String? value) {
        _pmChannel = value ?? _pmChannels.first;
        setState(() {});
      },
    );
  }

  DropdownButtonFormField<String> getRxNameDropdown() {
    List<DropdownMenuItem<String>> entries = [];
    for (String rxName in _rxNames) {
      var item = DropdownMenuItem<String>(
        value: rxName,
        child: Text(rxName),
      );
      entries.add(item);
    }
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: (_rxNames.contains(_rxName)) ? _rxName : (_rxNames.isNotEmpty ? _rxNames.first : null),
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
        setState(() {});
      },
    );
  }

  DropdownButtonFormField<String> getConfigTypeDD() {
    List<DropdownMenuItem<String>> entries = [];
    for (String cfg in _configTypes) {
      var item = DropdownMenuItem<String>(
        value: cfg,
        child: Text(cfg),
      );
      entries.add(item);
    }
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: (_configTypes.contains(_configType)) ? _configType : _configTypes.first,
      decoration: InputDecoration(
        labelText: "Select Config Type",
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (String? value) {
        _configType = value ?? _configTypes.first;
        setState(() {});
      },
    );
  }
}
