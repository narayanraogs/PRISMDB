import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:prism_db_editor/services/api_service.dart';

// A flexible widget for editing generic profile tables where ID should be hidden
class EditGenericProfile extends StatefulWidget {
  final Global global;
  final VoidCallback callback;
  final List<String>? initialData;
  final String tableName;
  final List<String> headers;

  const EditGenericProfile(this.global, this.callback, {
    this.initialData, 
    required this.tableName, 
    required this.headers,
    super.key
  });

  @override
  State<EditGenericProfile> createState() => _EditGenericProfileState();
}

class _EditGenericProfileState extends State<EditGenericProfile> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  
  // Specific dropdown state
  String? _commandingRequired; // For FrequencyProfile
  String? _pmChannel; // For DownlinkPowerProfile
  String? _ppmChannel; // For PulseProfile
  
  // SpectrumProfile specific
  String _centerFreqUnit = "MHz";
  String _spanUnit = "MHz";
  String _rbwUnit = "kHz";
  String _vbwUnit = "kHz";
  
  // LossMeasurementFrequencies specific
  String _lossFreqUnit = "Hz";

  bool _isEditing = false;
  String _currentId = "0"; 

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!.isNotEmpty && widget.global.rowSelected.isNotEmpty) {
      _isEditing = true;
      _populateData(widget.initialData!);
    } else {
       // Initialize empty controllers
      for (var h in widget.headers) {
         if (h != 'ID') {
           _controllers[h] = TextEditingController();
         }
      }
    }
  }

  void _populateData(List<String> data) {
    for (int i = 0; i < widget.headers.length; i++) {
      String header = widget.headers[i];
      String val = (i < data.length) ? data[i] : "";

      if (header == "ID") {
        _currentId = val;
        continue; 
      }
      
      // Special fields
      if (widget.tableName.toLowerCase() == 'frequencyprofile' && header == 'CommandingRequired') {
         _commandingRequired = (val == "1" || val.toLowerCase() == "yes") ? "Yes" : "No";
         continue;
      }
      if (widget.tableName.toLowerCase() == 'downlinkpowerprofile' && header == 'PMChannel') {
         _pmChannel = val;
         continue;
      }
      if (widget.tableName.toLowerCase() == 'pulseprofile' && header == 'PPMChannel') {
         _ppmChannel = val;
         continue;
      }
      
      // Spectrum Profile: CenterFrequency and Span are stored in Hz usually? 
      // Requirement: "Freq should be entered in Hz" -> Wait.
      // "Freq should have selection as Hz, kHz, MHz, GHz." 
      // "Freq should be entered in Hz" -> likely means stored in Hz or user enters number and selects unit?
      // "Span as Hz, kHz, MHz, RBW, VBW same as Span"
      // Wait, standard UI usually lets user enter Value + Unit.
      // If DB stores Hz, we convert to display unit for EDIT, and convert back to Hz for SAVE.
      // But user said "Freq should be enterred in Hz". This clashes with "selection as Hz, kHz...".
      // Maybe user means "Entered value is converted to Hz"? 
      // Let's assume user inputs a Number and a Unit.
      // And we save the result in Hz.
      
      if (widget.tableName.toLowerCase() == 'spectrumprofile') {
         if (header == 'CenterFrequency') {
             // Let's assume stored as Hz string.
             double freqHz = double.tryParse(val) ?? 0;
             // We can just keep it as is if we default to Hz.
             _controllers[header] = TextEditingController(text: val);
             _centerFreqUnit = "Hz"; // Default or auto-scale? Let's default Hz for accuracy
             continue;
         }
         if (header == 'Span') {
             _controllers[header] = TextEditingController(text: val);
             _spanUnit = "Hz";
             continue;
         }
         if (header == 'RBW') {
             _controllers[header] = TextEditingController(text: val);
             _rbwUnit = "Hz";
             continue;
         }
         if (header == 'VBW') {
             _controllers[header] = TextEditingController(text: val);
             _vbwUnit = "Hz";
             continue;
         }
      }
      
      // LossMeasurementFrequencies
      if (widget.tableName.toLowerCase() == 'lossmeasurementfrequencies') {
         if (header == 'Frequency') {
             _controllers[header] = TextEditingController(text: val);
             _lossFreqUnit = "Hz"; 
             continue;
         }
      }

      _controllers[header] = TextEditingController(text: (val == "NULL") ? "" : val);
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
               _isEditing ? "Edit ${widget.tableName}" : "Create New ${widget.tableName} Entry", 
               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
             ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: _buildFields(),
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
                       onPressed: widget.callback,
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

  List<Widget> _buildFields() {
    List<Widget> children = [];
    
    for (String header in widget.headers) {
      if (header == "ID") continue; // Skip ID

      // FrequencyProfile
      if (widget.tableName.toLowerCase() == 'frequencyprofile' && header == 'CommandingRequired') {
         children.add(_buildDropdown(
           header, 
           ['Yes', 'No'], 
           _commandingRequired, 
           (val) => setState(() => _commandingRequired = val)
         ));
         continue;
      }

      // DownlinkPowerProfile
      if (widget.tableName.toLowerCase() == 'downlinkpowerprofile' && header == 'PMChannel') {
         children.add(_buildDropdown(
           header, 
           ['A', 'B'], 
           _pmChannel, 
           (val) => setState(() => _pmChannel = val)
         ));
         continue;
      }

      // PulseProfile
      if (widget.tableName.toLowerCase() == 'pulseprofile' && header == 'PPMChannel') {
         children.add(_buildDropdown(
           header, 
           ['A', 'B'], 
           _ppmChannel, 
           (val) => setState(() => _ppmChannel = val)
         ));
         continue;
      }
      
      // SpectrumProfile Special Handling
      if (widget.tableName.toLowerCase() == 'spectrumprofile') {
         if (header == 'CenterFrequency') {
           children.add(_buildUnitField(header, _controllers[header]!, ['Hz', 'kHz', 'MHz', 'GHz'], _centerFreqUnit, (val) => setState(() => _centerFreqUnit = val!)));
           continue;
         }
         if (header == 'Span') {
           children.add(_buildUnitField(header, _controllers[header]!, ['Hz', 'kHz', 'MHz', 'GHz'], _spanUnit, (val) => setState(() => _spanUnit = val!)));
            continue;
         }
         // Note: User said "Freq should be enterred in Hz". This likely means the VALUE *entered* is treated as Hz?
         // OR "Freq should have selection...". 
         // If I select "MHz", and type "100", it means 100 MHz.
         // Before saving, strict requirement "Freq should be enterred in Hz" might mean "Store in Hz".
         
         // RBW/VBW same as Span (units)
         if (header == 'RBW') {
           children.add(_buildUnitField(header, _controllers[header]!, ['Hz', 'kHz', 'MHz', 'GHz'], _rbwUnit, (val) => setState(() => _rbwUnit = val!)));
           continue;
         }
         if (header == 'VBW') {
           children.add(_buildUnitField(header, _controllers[header]!, ['Hz', 'kHz', 'MHz', 'GHz'], _vbwUnit, (val) => setState(() => _vbwUnit = val!)));
           continue;
         }
      }
      
      // LossMeasurementFrequencies
      if (widget.tableName.toLowerCase() == 'lossmeasurementfrequencies') {
         if (header == 'Frequency') {
             children.add(_buildUnitField(header, _controllers[header]!, ['Hz', 'kHz', 'MHz', 'GHz'], _lossFreqUnit, (val) => setState(() => _lossFreqUnit = val!)));
             continue;
         }
      }
      
      // Generic Text Fields
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: TextFormField(
          controller: _controllers[header],
          decoration: _inputDecoration(header),
          validator: (v) => (v == null || v.isEmpty) ? "$header Required" : null,
        ),
      ));
    }
    
    return children;
  }

  Widget _buildUnitField(String label, TextEditingController controller, List<String> units, String currentUnit, ValueChanged<String?> onUnitChanged) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: controller,
                decoration: _inputDecoration(label),
                validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: currentUnit,
                items: units.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: onUnitChanged,
                decoration: _inputDecoration("Unit"),
                isExpanded: true,
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildDropdown(String label, List<String> options, String? value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: DropdownButtonFormField<String>(
        value: options.contains(value) ? value : null,
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: _inputDecoration(label),
        validator: (v) => v == null ? "Required" : null,
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
    
    for (String header in widget.headers) {
       if (header == "ID") {
         if (_isEditing) {
           values.add(_currentId); 
         } else {
           values.add("0"); 
         }
         continue;
       }

       // FrequencyProfile
       if (widget.tableName.toLowerCase() == 'frequencyprofile' && header == 'CommandingRequired') {
          values.add(_commandingRequired ?? "");
          continue;
       }
       // DownlinkPowerProfile
       if (widget.tableName.toLowerCase() == 'downlinkpowerprofile' && header == 'PMChannel') {
          values.add(_pmChannel ?? "");
          continue;
       }
       // PulseProfile
       if (widget.tableName.toLowerCase() == 'pulseprofile' && header == 'PPMChannel') {
          values.add(_ppmChannel ?? "");
          continue;
       }

       // SpectrumProfile
       if (widget.tableName.toLowerCase() == 'spectrumprofile') {
           if (header == 'CenterFrequency') {
              double val = double.tryParse(_controllers[header]?.text ?? "0") ?? 0;
              // Convert to Hz based on unit
              double multiplier = 1;
              switch(_centerFreqUnit) {
                case 'kHz': multiplier = 1e3; break;
                case 'MHz': multiplier = 1e6; break;
                case 'GHz': multiplier = 1e9; break;
              }
              values.add((val * multiplier).toString()); // Store as Hz
              continue;
           }
           if (header == 'Span') {
              double val = double.tryParse(_controllers[header]?.text ?? "0") ?? 0;
              // Convert to Hz based on unit
              double multiplier = 1;
              switch(_spanUnit) {
                case 'kHz': multiplier = 1e3; break;
                case 'MHz': multiplier = 1e6; break;
                case 'GHz': multiplier = 1e9; break;
              }
              values.add((val * multiplier).toString()); // Store as Hz
              continue;
           }
           if (header == 'RBW') {
              double val = double.tryParse(_controllers[header]?.text ?? "0") ?? 0;
              double multiplier = 1;
              switch(_rbwUnit) {
                case 'kHz': multiplier = 1e3; break;
                case 'MHz': multiplier = 1e6; break;
                case 'GHz': multiplier = 1e9; break;
              }
              values.add((val * multiplier).toInt().toString()); // Store as Int Hz
              continue;
           }
           if (header == 'VBW') {
              double val = double.tryParse(_controllers[header]?.text ?? "0") ?? 0;
              double multiplier = 1;
              switch(_vbwUnit) {
                case 'kHz': multiplier = 1e3; break;
                case 'MHz': multiplier = 1e6; break;
                case 'GHz': multiplier = 1e9; break;
              }
              values.add((val * multiplier).toInt().toString()); // Store as Int Hz
              continue;
           }
       }
       
       // LossMeasurementFrequencies
       if (widget.tableName.toLowerCase() == 'lossmeasurementfrequencies') {
           if (header == 'Frequency') {
              double val = double.tryParse(_controllers[header]?.text ?? "0") ?? 0;
              double multiplier = 1;
              switch(_lossFreqUnit) {
                case 'kHz': multiplier = 1e3; break;
                case 'MHz': multiplier = 1e6; break;
                case 'GHz': multiplier = 1e9; break;
              }
              values.add((val * multiplier).toString());
              continue;
           }
       }
       
       values.add(_controllers[header]?.text ?? "");
    }

    String clientID = widget.global.clientID;
    
    bool ok;
    if (_isEditing) {
       ok = await sendUpdateRequest(clientID, widget.tableName, values, primaryKey: widget.global.rowSelected);
    } else {
       ok = await sendAddRequest(clientID, widget.tableName, values);
    }

    if (ok) {
      widget.callback();
    }
  }
}
