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
  List<String> _deviceProfiles = [];
  String _deviceProfileName = '';

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

    // Fetch DeviceProfiles
    await _fetchValues("DeviceProfiles").then((values) {
        if (mounted) {
            _deviceProfiles = values;
            if (_deviceProfileName.isEmpty && values.isNotEmpty) _deviceProfileName = values.first;
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
        if (temp.ok) {
          return temp.values.where((val) => !val.toLowerCase().contains("copy")).toList();
        }
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

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5), width: 1.0),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(28.0),
        child: child,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget getButton(BuildContext context) {
    bool isNew = widget.global.rowSelected.trim().isEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 32.0),
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
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Cancel", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                if (!_formKey.currentState!.validate()) {
                  showMessage("Please check the inputs", true);
                  return;
                }
                update(!isNew);
              },
              icon: Icon(isNew ? Icons.add_circle_outline : Icons.save_outlined, size: 22),
              label: Text(isNew ? "Create Config" : "Save Changes", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> getChildren(BuildContext context) {
    List<Widget> children = [];

    List<Widget> generalFields = [];
    generalFields.add(_buildSectionHeader("General Configuration", Icons.settings_rounded));
    generalFields.add(_buildTextField(
      controller: _nameController,
      label: "Configuration Name",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Configuration name cannot be empty";
        }
        return null;
      },
    ));
    generalFields.add(const SizedBox(height: 20.0));
    generalFields.add(getConfigTypeDD());
    children.add(_buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: generalFields)));

    List<Widget> specificFields = [];
    specificFields.add(_buildSectionHeader("Specific Settings", Icons.tune_rounded));
    
    if (_configType == 'Rx') {
      specificFields.add(getRxNameDropdown());
      specificFields.add(const SizedBox(height: 20.0));
    }

    if (_configType == 'Tx') {
      specificFields.add(getTxNameDropdown());
      specificFields.add(const SizedBox(height: 20.0));
    }

    if (_configType == 'Tp') {
      specificFields.add(getTpNameDropdown());
      specificFields.add(const SizedBox(height: 20.0));
    }

    if (_configType == 'PL') {
      specificFields.add(getPlNameDropdown());
      specificFields.add(const SizedBox(height: 20.0));
    }

    specificFields.add(getTSMNameDropdown());

    if ((_configType == 'Rx') || (_configType == 'Tp')) {
      specificFields.add(const SizedBox(height: 20.0));
      specificFields.add(getCortexIFMDropdown());
      specificFields.add(const SizedBox(height: 20.0));
      specificFields.add(_buildTextField(
        controller: _ifController,
        label: "Intermediate Frequency",
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Required";
          if (int.tryParse(value) == null) return "Must be an integer";
          return null;
        },
      ));
      specificFields.add(const SizedBox(height: 20.0));
      specificFields.add(getProgAttnDD());
    }

    if ((_configType == 'Tx') || (_configType == 'Tp')) {
      specificFields.add(const SizedBox(height: 20.0));
      specificFields.add(getPMChannelDD());
    }

    specificFields.add(const SizedBox(height: 20.0));
    specificFields.add(getDeviceProfileDropdown());
    
    children.add(_buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: specificFields)));

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
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onChanged: onChanged,
      decoration: _buildInputDecoration(label),
      validator: validator,
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
    
    if (_configType == 'PL') {
        values.add(_plName);
    } else {
        values.add(_pmChannel); 
    }
    values.add(_deviceProfileName);
    values.add(_progAttnUsed);
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
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
             decoration: BoxDecoration(
               color: Theme.of(context).colorScheme.surface,
               border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5), width: 1.5)),
             ),
             child: Row(
               children: [
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: Theme.of(context).colorScheme.primaryContainer,
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Icon(
                     widget.global.rowSelected.isEmpty ? Icons.add_box_outlined : Icons.edit_note_rounded,
                     color: Theme.of(context).colorScheme.onPrimaryContainer,
                   ),
                 ),
                 const SizedBox(width: 20),
                 Text(
                   widget.global.rowSelected.isEmpty ? "Create Configuration" : "Edit Configuration", 
                   style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)
                 ),
               ],
             ),
          ),
          
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
              ),
            ),
          ),
          
          Container(
             padding: EdgeInsets.zero,
             decoration: BoxDecoration(
               color: Theme.of(context).colorScheme.surface,
               border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5), width: 1.5)),
             ),
             child: button
          ),
        ],
      ),
    );
  }

  DropdownButtonFormField<String> getTxNameDropdown() {
    List<String> list = List.from(_txNames);
    if (_txName.isNotEmpty && !list.contains(_txName)) {
      list.add(_txName);
    }
    List<DropdownMenuItem<String>> entries = list.map((txName) => DropdownMenuItem<String>(value: txName, child: Text(txName))).toList();
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: (list.contains(_txName)) ? _txName : (list.isNotEmpty ? list.first : null),
      decoration: _buildInputDecoration("Transmitter Name"),
      onChanged: (String? value) {
        _txName = value ?? (list.isNotEmpty ? list.first : '');
        setState(() {});
      },
    );
  }

  DropdownButtonFormField<String> getTpNameDropdown() {
    List<String> list = List.from(_tpNames);
    if (_tpName.isNotEmpty && !list.contains(_tpName)) {
      list.add(_tpName);
    }
    List<DropdownMenuItem<String>> entries = list.map((tpName) => DropdownMenuItem<String>(value: tpName, child: Text(tpName))).toList();
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: (list.contains(_tpName)) ? _tpName : (list.isNotEmpty ? list.first : null),
      decoration: _buildInputDecoration("Transponder Name"),
      onChanged: (String? value) {
        _tpName = value ?? (list.isNotEmpty ? list.first : '');
        setState(() {});
      },
    );
  }

  DropdownButtonFormField<String> getPlNameDropdown() {
    List<String> list = List.from(_plNames);
    if (_plName.isNotEmpty && !list.contains(_plName)) {
      list.add(_plName);
    }
    List<DropdownMenuItem<String>> entries = list.map((plName) => DropdownMenuItem<String>(value: plName, child: Text(plName))).toList();
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: (list.contains(_plName)) ? _plName : (list.isNotEmpty ? list.first : null),
      decoration: _buildInputDecoration("Payload Name"),
      onChanged: (String? value) {
        _plName = value ?? (list.isNotEmpty ? list.first : '');
        setState(() {});
      },
    );
  }

  DropdownButtonFormField<String> getTSMNameDropdown() {
    List<String> list = List.from(_tsmNames);
    if (_tsmName.isNotEmpty && !list.contains(_tsmName)) {
      list.add(_tsmName);
    }
    List<DropdownMenuItem<String>> entries = list.map((tsm) => DropdownMenuItem<String>(value: tsm, child: Text(tsm))).toList();
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: (list.contains(_tsmName)) ? _tsmName : (list.isNotEmpty ? list.first : null),
      decoration: _buildInputDecoration("TSM Configuration Name"),
      onChanged: (String? value) {
        _tsmName = value ?? (list.isNotEmpty ? list.first : '');
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
      decoration: _buildInputDecoration("Cortex IFM"),
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
      decoration: _buildInputDecoration("Programmable Attn Used?"),
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
      decoration: _buildInputDecoration("Power Meter Channel"),
      onChanged: (String? value) {
        _pmChannel = value ?? _pmChannels.first;
        setState(() {});
      },
    );
  }

  DropdownButtonFormField<String> getRxNameDropdown() {
    List<String> list = List.from(_rxNames);
    if (_rxName.isNotEmpty && !list.contains(_rxName)) {
      list.add(_rxName);
    }
    List<DropdownMenuItem<String>> entries = list.map((rxName) => DropdownMenuItem<String>(value: rxName, child: Text(rxName))).toList();
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: (list.contains(_rxName)) ? _rxName : (list.isNotEmpty ? list.first : null),
      decoration: _buildInputDecoration("Receiver Name"),
      onChanged: (String? value) {
        _rxName = value ?? (list.isNotEmpty ? list.first : '');
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
      decoration: _buildInputDecoration("Select Config Type"),
      onChanged: (String? value) {
        _configType = value ?? _configTypes.first;
        setState(() {});
      },
    );
  }

  DropdownButtonFormField<String> getDeviceProfileDropdown() {
    List<String> list = List.from(_deviceProfiles);
    if (_deviceProfileName.isNotEmpty && !list.contains(_deviceProfileName)) {
      list.add(_deviceProfileName);
    }
    List<DropdownMenuItem<String>> entries = list.map((dp) => DropdownMenuItem<String>(value: dp, child: Text(dp))).toList();
    return DropdownButtonFormField<String>(
      items: entries,
      isExpanded: true,
      value: (list.contains(_deviceProfileName)) ? _deviceProfileName : (list.isNotEmpty ? list.first : null),
      decoration: _buildInputDecoration("Device Profile Name"),
      onChanged: (String? value) {
        _deviceProfileName = value ?? (list.isNotEmpty ? list.first : '');
        setState(() {});
      },
    );
  }
}
