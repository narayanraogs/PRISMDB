import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class DeviceIP extends StatefulWidget {
  final Global global;
  final VoidCallback callback;
  final List<String>? initialData;

  const DeviceIP(this.global, this.callback, {super.key, this.initialData});

  @override
  State<DeviceIP> createState() => StateDeviceIP();
}

class StateDeviceIP extends State<DeviceIP> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  
  // Make and Type variables and lists
  List<String> _deviceMakes = [
    'N9040B', 'N9030B', 'N9030A', 
    'E8267D', 'E8257D', 
    'NRX', 'ML2488B', 'N1912A', 
    'Cortex', 'TTCP', 'DataPattern', 'TSM'
  ];
  String? _selectedMake;
  
  // Types are derived from Make, so we might not need a static list of all types, 
  // but we need to track selection.
  String? _selectedType;
  List<String> _availableTypes = [];

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _controlPortController = TextEditingController();
  final TextEditingController _altControlPortController = TextEditingController();
  final TextEditingController _readPortController = TextEditingController();
  final TextEditingController _dopplerPortController = TextEditingController();
  final TextEditingController _timeoutController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default Timeout
    _timeoutController.text = "5000"; 
    
    sendRequest();
  }

  void sendRequest() async {
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _populateFromInitialData();
    } else if (widget.global.rowSelected.isNotEmpty) {
      await _fetchRowData();
    }
    if (mounted) setState(() {});
  }

  void _populateFromInitialData() {
    List<String> data = widget.initialData!;
    if (data.length >= 10) {
      _nameController.text = data[1];
      
      String make = data[2];
      if (_deviceMakes.contains(make)) {
        _selectedMake = make;
        _updateAvailableTypes();
      } else {
        _selectedMake = null;
        _availableTypes = [];
      }
      
      String type = data[3];
      if (_availableTypes.contains(type)) {
        _selectedType = type;
      } else {
        // If loaded type isn't in valid list for loaded make, maybe add it or leave null?
        // For strict compliance, if DataPattern, it might be GTx
        _selectedType = null;
        if (_availableTypes.isNotEmpty) _selectedType = _availableTypes.first;
      }
      
      _ipController.text = data[4];
      _controlPortController.text = data[5];
      _altControlPortController.text = data[6];
      _readPortController.text = data[7];
      _dopplerPortController.text = data[8];
      _timeoutController.text = data[9];
    }
  }

  Future<void> _fetchRowData() async {
    RowDisplayRequest req = RowDisplayRequest();
    req.id = widget.global.clientID;
    req.tableName = "Devices";
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
        if (temp.ok && temp.values.length >= 9) { 
           // Handle shift if ID is missing (length 9) vs included (length 10)
           List<String> vals = temp.values;
           if (vals.length == 9) {
             // Shift insert dummy at 0
             vals.insert(0, "");
           }
           
           if (vals.length >= 10) {
              _nameController.text = vals[1];

              String make = vals[2];
              if (_deviceMakes.contains(make)) {
                _selectedMake = make;
                _updateAvailableTypes();
              }
              
              String type = vals[3];
              if (_availableTypes.contains(type)) {
                _selectedType = type;
              }

              _ipController.text = vals[4];
              _controlPortController.text = vals[5];
              _altControlPortController.text = vals[6];
              _readPortController.text = vals[7];
              _dopplerPortController.text = vals[8];
              _timeoutController.text = vals[9];
           }
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
  
  void _updateAvailableTypes() {
    if (_selectedMake == null) {
      _availableTypes = [];
      _selectedType = null;
      return;
    }
    
    switch (_selectedMake) {
      case 'N9040B':
      case 'N9030B':
      case 'N9040A':
        _availableTypes = ['SA', 'VSA'];
        break;
      case 'E8267D':
      case 'E8257D':
        _availableTypes = ['SG', 'VSG'];
        break;
      case 'NRX':
      case 'ML2488B':
      case 'N1912A':
        _availableTypes = ['PM', 'PPM'];
        break;
      case 'Cortex':
      case 'TTCP':
      case 'DataPattern':
        _availableTypes = ['GTx'];
        break;
      case 'TSM':
        _availableTypes = ['TSM'];
        break;
      default:
        _availableTypes = [];
    }
    
    // Reset selected type if strictly needed, or select first if forced
    if (_availableTypes.isNotEmpty) {
       // if current selectedType is valid, keep it, else select first
       if (_selectedType == null || !_availableTypes.contains(_selectedType)) {
         _selectedType = _availableTypes.first;
       }
    } else {
      _selectedType = null;
    }
    
    _autoFillPorts();
  }

  void _autoFillPorts() {
    // Apply Timeout globally
    if (_timeoutController.text.isEmpty) _timeoutController.text = "5000";

    if (_selectedType == null) return;
    
    // Default Nullify fields that should be NULL (empty string for UI)
    // We will set them specifically where needed.
    
    // SA, SG, PM, VSG, PPM -> 5025 Control
    if (['SA', 'SG', 'PM', 'VSG', 'PPM'].contains(_selectedType)) {
       _controlPortController.text = "5025";
    }
    
    // PM, PPM, VSG -> Alt Control Port NULL
    if (['PM', 'PPM', 'VSG'].contains(_selectedType)) {
       _altControlPortController.text = "";
    }
    
    // VSA -> Alt 5125
    if (_selectedType == 'VSA') {
       _altControlPortController.text = "5125";
    }
    
    if (_selectedMake == 'TSM') {
      _controlPortController.text = "5000";
      _altControlPortController.text = ""; // Null
    }
    
    if (['Cortex', 'TTCP'].contains(_selectedMake)) {
      _controlPortController.text = "3001";
      _readPortController.text = "3000";
      _dopplerPortController.text = "3065";
      _altControlPortController.text = ""; // Null
    }
    
    if (_selectedMake == 'DataPattern') {
      _controlPortController.text = "0";
      _altControlPortController.text = "0";
      _readPortController.text = "0";
      _dopplerPortController.text = "0";
    }
  }

  // Handle Type Change specific logic (e.g. VSA switch)
  void _onTypeChanged(String? newValue) {
    setState(() {
      _selectedType = newValue;
      _autoFillPorts();
    });
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

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _buildInputDecoration(label),
      validator: validator,
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
              label: Text(isNew ? "Add Device" : "Save Changes", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

    // Basic Information Card
    children.add(_buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Basic Information", Icons.info_outline_rounded),
          _buildTextField(
            controller: _nameController,
            label: "Device Name",
            validator: (value) => (value == null || value.isEmpty) ? "Device Name is required" : null,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            items: _deviceMakes.map((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(val),
              );
            }).toList(),
            value: _selectedMake,
            decoration: _buildInputDecoration("Device Make"),
            onChanged: (val) {
              setState(() {
                _selectedMake = val;
                _updateAvailableTypes();
              });
            },
            validator: (value) => value == null ? "Select Device Make" : null,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            items: _availableTypes.map((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(val),
              );
            }).toList(),
            value: _selectedType,
            decoration: _buildInputDecoration("Device Type"),
            onChanged: _onTypeChanged,
            validator: (value) => value == null ? "Select Device Type" : null,
          ),
        ],
      ),
    ));

    // Network Configuration Card
    children.add(_buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Network Configuration", Icons.wifi_rounded),
          _buildTextField(
            controller: _ipController,
            label: "IP Address",
            validator: (value) {
              if (value == null || value.isEmpty) return "IP Address is required";
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _timeoutController,
            label: "Timeout (ms)",
            keyboardType: TextInputType.number,
            validator: (value) {
                if (value != null && value.isNotEmpty && int.tryParse(value) == null) return "Must be integer";
                return null;
            }
          ),
        ],
      ),
    ));

    // Port Configuration Card
    List<Widget> portFields = [];
    portFields.add(_buildSectionHeader("Port Configuration", Icons.settings_ethernet_rounded));
    portFields.add(_buildTextField(
      controller: _controlPortController,
      label: "Control Port",
      keyboardType: TextInputType.number,
      validator: (value) {
          if (value == null || value.isEmpty) return "Required";
          if (int.tryParse(value) == null) return "Must be integer";
          return null;
      }
    ));

    bool showAltControlPort = true;
    if (_selectedType != null) {
      if (['SA', 'PM', 'PPM', 'SG', 'TSM', 'GTx', 'VSG'].contains(_selectedType)) {
        showAltControlPort = false;
      }
    }
    
    if (showAltControlPort) {
        portFields.add(const SizedBox(height: 20));
        portFields.add(_buildTextField(
          controller: _altControlPortController,
          label: "Alternate Control Port",
          keyboardType: TextInputType.number,
        ));
    }

    bool showReadPort = true;
    if (_selectedType != null) {
      if (['SA', 'PM', 'PPM', 'SG', 'TSM', 'VSA', 'VSG'].contains(_selectedType)) {
        showReadPort = false;
      }
    }

    if (showReadPort) {
        portFields.add(const SizedBox(height: 20));
        portFields.add(_buildTextField(
          controller: _readPortController,
          label: "Read Port",
          keyboardType: TextInputType.number,
        ));
    }

    bool showDopplerPort = true;
    if (_selectedType != null) {
      if (['SA', 'PM', 'PPM', 'SG', 'TSM', 'VSA', 'VSG'].contains(_selectedType)) {
        showDopplerPort = false;
      }
    }

    if (showDopplerPort) {
        portFields.add(const SizedBox(height: 20));
        portFields.add(_buildTextField(
          controller: _dopplerPortController,
          label: "Doppler Port",
          keyboardType: TextInputType.number,
        ));
    }

    children.add(_buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: portFields,
      ),
    ));

    return children;
  }

  void update(bool edit) async {
    var clientID = widget.global.clientID;
    var tableName = "Devices";
    List<String> values = [];
    
    values.add(''); // 0: ID
    values.add(_nameController.text);
    values.add(_selectedMake ?? "");
    values.add(_selectedType ?? "");
    values.add(_ipController.text);
    values.add(_controlPortController.text);
    values.add(_altControlPortController.text);
    values.add(_readPortController.text);
    values.add(_dopplerPortController.text);
    values.add(_timeoutController.text);

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
                   widget.global.rowSelected.isEmpty ? "Add New Device" : "Edit Device Configuration", 
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
}
