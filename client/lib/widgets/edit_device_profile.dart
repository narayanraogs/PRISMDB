import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:prism_db_editor/services/api_service.dart';

class EditDeviceProfile extends StatefulWidget {
  final Global global;
  final VoidCallback callback;
  final List<String>? initialData;

  const EditDeviceProfile(this.global, this.callback, {this.initialData, super.key});

  @override
  State<EditDeviceProfile> createState() => _EditDeviceProfileState();
}

class _EditDeviceProfileState extends State<EditDeviceProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  // Selected values for dropdowns
  final Map<String, String?> _selectedDevices = {
    'SAName': null,
    'VSAName': null,
    'PMName': null,
    'PPMName': null,
    'TSMName': null,
    'GTxName': null,
    'SGName': null,
    'VSGName': null,
  };

  // Device Data: Type -> List of DeviceNames
  final Map<String, List<String>> _devicesByType = {};
  // Also keep a list of all devices just in case or for "Other"
  final List<String> _allDevices = [];

  bool _isEditing = false;
  String _currentId = "0";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
    
    if (widget.initialData != null && widget.initialData!.isNotEmpty && widget.global.rowSelected.isNotEmpty) {
      _isEditing = true;
      _populateData(widget.initialData!);
    }
  }

  Future<void> _fetchDevices() async {
    try {
      TableDisplayRequest tabReq = TableDisplayRequest();
      tabReq.id = widget.global.clientID;
      tabReq.tableName = "Devices";
      
      final response = await http.post(
        Uri.parse('http://localhost:8085/getTables'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(tabReq.toJSON()),
      );

      if (response.statusCode == 200) {
        var tableDetails = TableDisplayDetails.fromJson(jsonDecode(response.body));
        if (tableDetails.ok) {
           int nameIdx = tableDetails.header.indexOf("DeviceName");
           int typeIdx = tableDetails.header.indexOf("DeviceType");
           
           if (nameIdx != -1 && typeIdx != -1) {
             for (var row in tableDetails.details) {
               if (row.details.length > nameIdx && row.details.length > typeIdx) {
                 String name = row.details[nameIdx];
                 String type = row.details[typeIdx]; // keep original case usually?
                 
                 _allDevices.add(name);
                 
                 // Normalize type key for easier matching (e.g. 'Spectrum Analyzer' -> 'SA'?? Or just use raw)
                 // Based on typical DBs, types are likely 'SA', 'VSA', 'PM', etc. matching the columns.
                 // Let's store raw type.
                 
                 if (!_devicesByType.containsKey(type)) {
                   _devicesByType[type] = [];
                 }
                 _devicesByType[type]!.add(name);
               }
             }
           }
        }
      }
    } catch (e) {
      debugPrint("Error fetching devices: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateData(List<String> data) {
    // Expected Data: [ID, DeviceProfileName, SAName, VSAName, PMName, PPMName, TSMName, GTxName, SGName, VSGName]
    if (data.length < 10) return;

    _currentId = data[0];
    _nameController.text = data[1]; // DeviceProfileName
    
    _setDevice('SAName', data[2]);
    _setDevice('VSAName', data[3]);
    _setDevice('PMName', data[4]);
    _setDevice('PPMName', data[5]);
    _setDevice('TSMName', data[6]);
    _setDevice('GTxName', data[7]);
    _setDevice('SGName', data[8]);
    _setDevice('VSGName', data[9]);
  }

  void _setDevice(String key, String val) {
    if (val != "NULL" && val.isNotEmpty) {
      _selectedDevices[key] = val;
    } else {
      _selectedDevices[key] = null;
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
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
             decoration: BoxDecoration(
               color: Colors.white,
               border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
             ),
             child: Text(
               _isEditing ? "Edit Device Profile" : "Create Device Profile", 
               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
             ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Device Profile Name
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: TextFormField(
                            controller: _nameController,
                            decoration: _inputDecoration("Device Profile Name"),
                            validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          ),
                        ),
                        
                        // Device Fields
                        _buildDeviceDropdown("SA Name", "SAName", "SA"),
                        _buildDeviceDropdown("VSA Name", "VSAName", "VSA"),
                        _buildDeviceDropdown("PM Name", "PMName", "PM"),
                        _buildDeviceDropdown("PPM Name", "PPMName", "PPM"),
                        _buildDeviceDropdown("TSM Name", "TSMName", "TSM"),
                        _buildDeviceDropdown("GTx Name", "GTxName", "GTx"),
                        _buildDeviceDropdown("SG Name", "SGName", "SG"),
                        _buildDeviceDropdown("VSG Name", "VSGName", "SG"),
                      ],
                    ),
                  ),
                ),
          ),
          
          Container(
             decoration: BoxDecoration(
               color: Colors.grey.shade50,
               border: Border(top: BorderSide(color: Colors.grey.shade200)),
             ),
             child: Padding(
               padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
               child: Row(
                 children: [
                   Expanded(
                     child: OutlinedButton(
                       onPressed: widget.callback, // Usually cancels back to table
                       style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                       child: const Text("Cancel"),
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: FilledButton.icon(
                       onPressed: _handleSave,
                       icon: Icon(_isEditing ? Icons.save : Icons.add, size: 20),
                       label: Text(_isEditing ? "Save Changes" : "Create"),
                       style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                     ),
                   ),
                 ],
               ),
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceDropdown(String label, String key, String typeHint) {
    // Try to find devices for this type
    // If not found, check if we have a key that matches case-insensitive, or just show all
    
    List<String> options = [];
    
    // Exact match
    if (_devicesByType.containsKey(typeHint)) {
       options = _devicesByType[typeHint]!;
    } else {
       // Try case insensitive
       String? distinctKey = _devicesByType.keys.firstWhere(
         (k) => k.toLowerCase() == typeHint.toLowerCase(), 
         orElse: () => ""
       );
       if (distinctKey.isNotEmpty) {
          options = _devicesByType[distinctKey]!;
       } else {
          // Fallback: If no type found, maybe the user hasn't set types correctly?
          // For now, let's show ALL devices if specific type list is empty, 
          // OR if the user asked for "correspondingly" maybe they expect filtering.
          // Let's assume if the list is empty, we show nothing (safe) or all?
          // Showing all is safer if type strings mismatch.
          options = _allDevices;
       }
    }
    
    // Ensure current value is in options
    String? currentVal = _selectedDevices[key];
    if (currentVal != null && !options.contains(currentVal)) {
      options = List.from(options)..add(currentVal); // Copy and add
    }

    // Sort
    options.sort();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: DropdownButtonFormField<String>(
        value: currentVal,
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) {
          setState(() {
            _selectedDevices[key] = val;
          });
        },
        decoration: _inputDecoration(label),
        // Allow null/empty? Usually yes for profile fields unless mandatory. 
        // Models say sql.NullString for all except ID and Name.
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

  void _handleSave() async {
    if (_formKey.currentState?.validate() != true) return;

    List<String> values = [];
    
    // Order: DeviceProfileName, SAName, VSAName, PMName, PPMName, TSMName, GTxName, SGName, VSGName
    values.add(_nameController.text.trim());
    values.add(_selectedDevices['SAName'] ?? "");
    values.add(_selectedDevices['VSAName'] ?? "");
    values.add(_selectedDevices['PMName'] ?? "");
    values.add(_selectedDevices['PPMName'] ?? "");
    values.add(_selectedDevices['TSMName'] ?? "");
    values.add(_selectedDevices['GTxName'] ?? "");
    values.add(_selectedDevices['SGName'] ?? "");
    values.add(_selectedDevices['VSGName'] ?? "");

    String clientID = widget.global.clientID;
    String tableName = "DeviceProfile";
    
    bool ok;
    if (_isEditing) {
       // Update usually needs ID. 
       ok = await sendUpdateRequest(clientID, tableName, values, primaryKey: widget.global.rowSelected);
    } else {
       ok = await sendAddRequest(clientID, tableName, values);
    }

    if (ok) {
      widget.callback();
    }
  }
}
