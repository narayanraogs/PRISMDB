import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:prism_db_editor/services/api_service.dart';

class EditTests extends StatefulWidget {
  final Global global;
  final VoidCallback callback;
  final List<String>? initialData;

  const EditTests(this.global, this.callback, {this.initialData, super.key});

  @override
  State<EditTests> createState() => _EditTestsState();
}

class _EditTestsState extends State<EditTests> {
  final _formKey = GlobalKey<FormState>();
  
  // Table Fields (excluding ID)
  String? _selectedConfigName;
  String _configType = ''; // To filter TestTypes
  String? _selectedTestType;
  String? _selectedTestCategory;
  
  // Profile Selected Values
  final Map<String, String?> _selectedProfiles = {
    'ULProfileName': null,
    'DLProfileName': null,
    'PowerProfileName': null,
    'FrequencyProfileName': null,
    'DownlinkPowerProfileName': null,
    'PulseProfileName': null,
    'TRMProfileName': null,
    'TMProfileName': null,
  };

  // State Data
  List<String> _configNames = [];
  Map<String, String> _configTypeMap = {}; // Name -> Type

  // Profile Options Data
  final Map<String, List<String>> _profileOptions = {
    'ULProfileName': [],
    'DLProfileName': [],
    'PowerProfileName': [],
    'FrequencyProfileName': [],
    'DownlinkPowerProfileName': [],
    'PulseProfileName': [],
    'TRMProfileName': [],
    'TMProfileName': [],
  };

  // Dropdown Options Maps
  final Map<String, List<String>> _testTypesByConfig = {
    'Rx': ['RFUplink', 'CommandDynamic', 'LockDynamic', 'CarrierAcquisition', 'LoopStress'],
    'Tx': ['Power', 'Frequency', 'Spurious', 'Harmonics', 'Bandwidth', 'ModIndex'],
    'Tp': ['ModIndex', 'ToneRanging', 'SimutaneousCommandingAndRanging'],
    'PL': ['PulseMeasurement', 'PulseAnalysis', 'HighResolutionPulse', 'SpectrogramAnalysis', 'PulseBandwidth', 'PulseFrequency', 'TRMAnalysis', 'PulseUplink'], // Assuming PL maps to SpecPL/Payload?
  };

  final Map<String, List<String>> _categoriesByTestType = {
    'RFUplink': [], // Null
    'CommandDynamic': ['Verify', 'Establish', 'Doppler'],
    'LockDynamic': ['Verify', 'Establish', 'Doppler'],
    'CarrierAcquisition': ['Normal', 'Extreme'],
    'LoopStress': ['Normal', 'Extreme'],
    'Harmonics': ['Harmonic', 'Sub-Harmonic'],
    'Spurious': ['In-Band', 'Out-Band'],
    'PulseMeasurement': ['PPM'],
    'PulseAnalysis': ['VSA'],
    'HighResolutionPulse': ['VSA'],
    'SpectrogramAnalysis': ['VSA'],
    'TRMAnalysis': ['VSA'],
    'PulseBandwidth': ['SA'],
    'PulseFrequency': ['SA'],
    'Bandwidth': [],    // Not specified
    'Power': [],        // Not specified
    'Frequency': [],    // Not specified
    'ModIndex': [],     // Not specified
    'ToneRanging': [],
    'SimutaneousCommandingAndRanging': [],
    'PulseUplink': [],
  };
  
  bool _isEditing = false;
  String _currentId = "0";

  @override
  void initState() {
    super.initState();
    _fetchConfigurations();
    _fetchProfiles();
    
    if (widget.initialData != null && widget.initialData!.isNotEmpty && widget.global.rowSelected.isNotEmpty) {
      _isEditing = true;
      _populateData(widget.initialData!);
    }
  }

  void _fetchConfigurations() async {
    // Fetch all configurations to populate ConfigName dropdown and mapping
    try {
      TableDisplayRequest tabReq = TableDisplayRequest();
      tabReq.id = widget.global.clientID;
      tabReq.tableName = "Configurations";
      
      final response = await http.post(
        Uri.parse('http://localhost:8085/getTables'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(tabReq.toJSON()),
      );

      if (response.statusCode == 200) {
        var tableDetails = TableDisplayDetails.fromJson(jsonDecode(response.body));
        if (tableDetails.ok) {
           List<String> names = [];
           Map<String, String> typeMap = {};
           
           int nameIdx = tableDetails.header.indexOf("ConfigName");
           int typeIdx = tableDetails.header.indexOf("ConfigType");
           
           if (nameIdx != -1 && typeIdx != -1) {
             for (var row in tableDetails.details) {
               if (row.details.length > typeIdx && row.details.length > nameIdx) {
                 String name = row.details[nameIdx];
                 String type = row.details[typeIdx];
                 names.add(name);
                 typeMap[name] = type;
               }
             }
           }
           
           if (mounted) {
             setState(() {
               _configNames = names;
               _configTypeMap = typeMap;
               
               if (_selectedConfigName != null && _configTypeMap.containsKey(_selectedConfigName)) {
                  String? type = _configTypeMap[_selectedConfigName];
                  if (type != null) _configType = _normalizeConfigType(type);
               }
             });
           }
        }
      }
    } catch (e) {
      debugPrint("Error fetching configs: $e");
    }
  }

  void _fetchProfiles() async {
    // Parallel fetch for all profile tables
    await Future.wait([
        _fetchTableNames("SpectrumProfile", "Name", 'ULProfileName'),
        _fetchTableNames("SpectrumProfile", "Name", 'DLProfileName'),
        _fetchTableNames("PowerProfile", "Name", 'PowerProfileName'),
        _fetchTableNames("FrequencyProfile", "Name", 'FrequencyProfileName'),
        _fetchTableNames("DownlinkPowerProfile", "Name", 'DownlinkPowerProfileName'),
        _fetchTableNames("PulseProfile", "Name", 'PulseProfileName'),
        _fetchTableNames("TRMProfile", "Name", 'TRMProfileName'),
        _fetchTableNames("TMProfile", "Name", 'TMProfileName'),
    ]);
    if (mounted) setState(() {});
  }

  Future<void> _fetchTableNames(String tableName, String columnName, String key) async {
    try {
      TableDisplayRequest tabReq = TableDisplayRequest();
      tabReq.id = widget.global.clientID;
      tabReq.tableName = tableName;
      
      final response = await http.post(
        Uri.parse('http://localhost:8085/getTables'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(tabReq.toJSON()),
      );

      if (response.statusCode == 200) {
        var tableDetails = TableDisplayDetails.fromJson(jsonDecode(response.body));
        if (tableDetails.ok) {
           int colIdx = tableDetails.header.indexOf(columnName);
           Set<String> values = {};
           
           if (colIdx != -1) {
             for (var row in tableDetails.details) {
               if (row.details.length > colIdx) {
                 String val = row.details[colIdx];
                 if (val != "NULL" && val.isNotEmpty) {
                   values.add(val);
                 }
               }
             }
           }
           // Use Set to ensure uniqueness, then list
           _profileOptions[key] = values.toList()..sort();
        }
      }
    } catch (e) {
       debugPrint("Error fetching $tableName: $e");
    }
  }

  String _normalizeConfigType(String raw) {
    String lower = raw.toLowerCase();
    if (lower.contains("rx")) return "Rx";
    if (lower.contains("tx")) return "Tx";
    if (lower.contains("tp") || lower.contains("transponder")) return "Tp";
    if (lower.contains("pl") || lower.contains("payload")) return "PL";
    return raw; 
  }

  void _populateData(List<String> data) {
    // Expected Data from Server (Tests Table):
    // [ID, ConfigName, TestType, TestCategory, ULProfileName, DLProfileName, PowerProfileName, FrequencyProfileName, DownlinkPowerProfileName, PulseProfileName, TRMProfileName, TMProfileName]
    if (data.length < 12) return;

    _currentId = data[0];
    _selectedConfigName = data[1];
    _selectedTestType = data[2];
    _selectedTestCategory = (data[3] == "NULL" || data[3].isEmpty) ? null : data[3];
    
    _setProfile('ULProfileName', data[4]);
    _setProfile('DLProfileName', data[5]);
    _setProfile('PowerProfileName', data[6]);
    _setProfile('FrequencyProfileName', data[7]);
    _setProfile('DownlinkPowerProfileName', data[8]);
    _setProfile('PulseProfileName', data[9]);
    _setProfile('TRMProfileName', data[10]);
    _setProfile('TMProfileName', data[11]);
  }

  void _setProfile(String key, String val) {
    String? cleanVal = (val == "NULL" || val.isEmpty) ? null : val;
    _selectedProfiles[key] = cleanVal;
    
    // Ensure value is in options if not present (to avoid dropdown error)
    if (cleanVal != null) {
       // We'll handle this in build time or just add it to options if we want.
       // But fetchProfiles is async, so better handle in build.
    }
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
               _isEditing ? "Edit Test" : "Create New Test", 
               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
             ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildChildren(),
                ),
              ),
            ),
          ),
          
          Container(
             decoration: BoxDecoration(
               color: Colors.grey.shade50,
               border: Border(top: BorderSide(color: Colors.grey.shade200)),
             ),
             child: _buildButtons()
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChildren() {
    List<Widget> children = [];
    
    // 2. Config Name Dropdown
    children.add(const Text("Configuration Name", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)));
    children.add(const SizedBox(height: 8));
    children.add(DropdownButtonFormField<String>(
      value: _configNames.contains(_selectedConfigName) ? _selectedConfigName : null,
      items: _configNames.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedConfigName = val;
            _configType = _normalizeConfigType(_configTypeMap[val] ?? "");
            _selectedTestType = null; // Reset choices
            _selectedTestCategory = null;
          });
        }
      },
      decoration: _inputDecoration("Select Configuration"),
      validator: (v) => v == null ? "Required" : null,
    ));
    children.add(const SizedBox(height: 16));

    if (_selectedConfigName == null) return children;

    // 3. Test Type Dropdown (Filtered by ConfigType)
    List<String> testTypes = _testTypesByConfig[_configType] ?? [];
    
    // Add logic to include current selected test type if not in list (for edge cases)
    if (_selectedTestType != null && !testTypes.contains(_selectedTestType)) {
       testTypes.add(_selectedTestType!);
    }

    children.add(const Text("Test Type", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)));
    children.add(const SizedBox(height: 8));
    children.add(DropdownButtonFormField<String>(
      value: _selectedTestType,
      items: testTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (val) {
         setState(() {
           _selectedTestType = val;
           _selectedTestCategory = null;
         });
      },
      decoration: _inputDecoration("Select Test Type"),
      validator: (v) => v == null ? "Required" : null,
    ));
    children.add(const SizedBox(height: 16));

    if (_selectedTestType == null) return children;

    // 4. Test Category Dropdown
    List<String> categories = _categoriesByTestType[_selectedTestType] ?? [];
    
    if (categories.isNotEmpty) {
      children.add(const Text("Test Category", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)));
      children.add(const SizedBox(height: 8));
      children.add(DropdownButtonFormField<String>(
        value: categories.contains(_selectedTestCategory) ? _selectedTestCategory : null,
        items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) {
          setState(() {
            _selectedTestCategory = val;
          });
        },
        decoration: _inputDecoration("Select Category"),
      ));
      children.add(const SizedBox(height: 16));
    }

    // 5. Profiles Mappings (Visibility)
    children.addAll(_buildProfileFields());

    return children;
  }

  List<Widget> _buildProfileFields() {
    List<Widget> fields = [];
    
    // Define Visibility Logic
    bool showUL = false;
    bool showDL = false;
    bool showPower = false;
    bool showFreq = false;
    bool showTM = false;
    bool showDLPower = false;
    bool showPulse = false;
    bool showTRM = false;

    String tt = _selectedTestType ?? "";
    String ct = _configType;

    // Logic based on User Request
    if (ct == 'Rx' || tt == 'RFUplink') {
      showUL = true;
      showPower = true;
      showFreq = true;
      showTM = true;
    } 
    else if (ct == 'Tx') {
       showDL = true;
       if (tt == 'Power') {
         showDLPower = true;
       }
    }
    else if (ct == 'Tp') {
       showUL = true;
       showPower = true;
       showFreq = true;
       showTM = true;
       showDL = true;
       showDLPower = true; 
    }
    else if (ct == 'PL') {
       showDL = true;
       showPulse = true;
       showTM = true;
       if (tt == 'TRMAnalysis') {
         showTRM = true;
       }
       if (tt == 'PulseUplink') {
         showUL = true;
       }
    }

    if (showUL) fields.add(_buildProfileDropdown('ULProfileName', "Uplink Profile"));
    if (showDL) fields.add(_buildProfileDropdown('DLProfileName', "Downlink Profile"));
    if (showPower) fields.add(_buildProfileDropdown('PowerProfileName', "Power Profile"));
    if (showFreq) fields.add(_buildProfileDropdown('FrequencyProfileName', "Frequency Profile"));
    if (showDLPower) fields.add(_buildProfileDropdown('DownlinkPowerProfileName', "Downlink Power Profile"));
    if (showPulse) fields.add(_buildProfileDropdown('PulseProfileName', "Pulse Profile"));
    if (showTRM) fields.add(_buildProfileDropdown('TRMProfileName', "TRM Profile"));
    if (showTM) fields.add(_buildProfileDropdown('TMProfileName', "TM Profile"));

    return fields;
  }

  Widget _buildProfileDropdown(String key, String label) {
    List<String> options = _profileOptions[key] ?? [];
    String? currentValue = _selectedProfiles[key];
    
    // If current value is set but not in options (fetched yet or deleted), add it temporarily so it shows
    if (currentValue != null && !options.contains(currentValue)) {
      options.add(currentValue);
      // Sort again? Or just leave at end.
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) {
          setState(() {
            _selectedProfiles[key] = val;
          });
        },
        decoration: _inputDecoration(label),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.withOpacity(0.04),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                widget.global.subMode = SubModes.showTables;
                widget.callback();
              },
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
              child: const Text("Cancel"),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: _handleSave,
              icon: Icon(_isEditing ? Icons.save : Icons.add, size: 20),
              label: Text(_isEditing ? "Save Changes" : "Create Test"),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSave() async {
    if (_formKey.currentState?.validate() != true) return;

    List<String> values = [];
    
    // Server expects Order:
    // [ConfigName, TestType, TestCategory, ULProfileName, DLProfileName, PowerProfileName, FrequencyProfileName, DownlinkPowerProfileName, PulseProfileName, TRMProfileName, TMProfileName]
   
    values.add(_selectedConfigName!);
    values.add(_selectedTestType!);
    values.add(_selectedTestCategory ?? "");
    
    values.add(_selectedProfiles['ULProfileName'] ?? "");
    values.add(_selectedProfiles['DLProfileName'] ?? "");
    values.add(_selectedProfiles['PowerProfileName'] ?? "");
    values.add(_selectedProfiles['FrequencyProfileName'] ?? "");
    values.add(_selectedProfiles['DownlinkPowerProfileName'] ?? "");
    values.add(_selectedProfiles['PulseProfileName'] ?? "");
    values.add(_selectedProfiles['TRMProfileName'] ?? "");
    values.add(_selectedProfiles['TMProfileName'] ?? "");
    
    String clientID = widget.global.clientID;
    String tableName = "Tests";
    
    bool ok;
    if (_isEditing) {
       ok = await sendUpdateRequest(clientID, tableName, values, primaryKey: _currentId);
    } else {
       ok = await sendAddRequest(clientID, tableName, values);
    }

    if (ok) {
      widget.callback();
    }
  }
}
