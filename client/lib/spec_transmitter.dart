import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/custom_dropdown.dart';
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class SpecTransmitter extends StatefulWidget {
  final Global global;
  final VoidCallback callback;
  final List<String>? initialData;

  const SpecTransmitter(this.global, this.callback, {this.initialData, super.key});

  @override
  State<SpecTransmitter> createState() => StateSpecTransmitter();
}

class StateSpecTransmitter extends State<SpecTransmitter> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _freqController = TextEditingController();
  TextEditingController _powerController = TextEditingController();
  TextEditingController _noOfSubCarroersController =
      TextEditingController(text: '0');
  TextEditingController _noOfHarmonicsController =
      TextEditingController(text: '0');
  TextEditingController _noOfSubHarmonicsController =
      TextEditingController(text: '0');
  TextEditingController _spuriousController =
      TextEditingController(text: '-50');
  TextEditingController _harmonicsController =
      TextEditingController(text: '-30');
  TextEditingController _allowedFreqDeviation =
      TextEditingController(text: '0');
  TextEditingController _allowedPowerDeviation =
      TextEditingController(text: '0.5');
  String freqResolution = 'Hz';
  String modulation = 'PM';
  String isBurst = 'No';
  ModulationDropdown modulationDropdown = ModulationDropdown((value) {});
  FrequencyDropDownMenu frequencyDropDown = FrequencyDropDownMenu((value) {});
  BurstModeDropdown burstDropdown = BurstModeDropdown((value) {});
  TextEditingController _burstTimeController = TextEditingController(text: '0');

  bool _showOthers = false;

  void setFreqResolution(String value) {
    freqResolution = value;
    calculateAllowedFrequencyDeviation();
  }

  void setModulation(String value) {
    modulation = value;
    setState(() {});
  }

  void setBurstMode(String value) {
    isBurst = value;
    setState(() {});
  }

  void sendRequest() async {
    if (widget.global.rowSelected == '') {
      return;
    }
    RowDisplayRequest req = RowDisplayRequest();
    req.id = widget.global.clientID;
    var tableName = getTableName(widget.global.tableSelected);
    req.tableName = tableName;
    req.primaryKey = widget.global.rowSelected;
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8085/getRows'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(req.toJSON()),
      );

      if (response.statusCode == 200) {
        var temp = RowDisplayDetails.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
        if (temp.ok) {
          _nameController.text = temp.values[0];
          _freqController.text = temp.values[1];
          freqResolution = 'Hz';
          _powerController.text = temp.values[2];
          _spuriousController.text = temp.values[3];
          _harmonicsController.text = temp.values[4];
          _allowedFreqDeviation.text = temp.values[5];
          _allowedPowerDeviation.text = temp.values[6];
          _noOfSubCarroersController.text = temp.values[7];
          _noOfHarmonicsController.text = temp.values[8];
          _noOfSubHarmonicsController.text = temp.values[9];
          modulation = temp.values[10].toUpperCase();
          isBurst = temp.values[11];
          _burstTimeController.text = temp.values[12];
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
    modulationDropdown = ModulationDropdown(setModulation, selected: modulation);
    frequencyDropDown = FrequencyDropDownMenu(setFreqResolution, selected: freqResolution);
    burstDropdown = BurstModeDropdown(setBurstMode, selected: isBurst);
    
    if (widget.initialData != null && widget.initialData!.isNotEmpty && widget.global.rowSelected.isNotEmpty) {
      _populateFromInitialData();
    } else {
      sendRequest();
    }
  }

  void _populateFromInitialData() {
    var data = widget.initialData!;
    // Correct Mapping based on SpecTx Schema:
    // 0: TxID, 1: Name, 2: Freq, 3: Power, 4: Spurious, 5: Harmonics, 
    // 6: FreqDev, 7: PowerDev, 8: Modulation, 9: IsBurst, 10: BurstTime
    
    if (data.length > 1) _nameController.text = data[1];
    if (data.length > 2) {
       _freqController.text = data[2];
       freqResolution = 'Hz'; 
    }
    if (data.length > 3) _powerController.text = data[3];
    if (data.length > 4) _spuriousController.text = data[4];
    if (data.length > 5) _harmonicsController.text = data[5];
    if (data.length > 6) _allowedFreqDeviation.text = data[6];
    if (data.length > 7) _allowedPowerDeviation.text = data[7];
    
    // Note: SubCarriers/Harmonics counts (indices 7,8,9 in old code) are NOT in SpecTx table.
    // They should default to 0 and likely come from separate tables if implemented.
    
    if (data.length > 8) {
      modulation = data[8].toUpperCase();
    }
    if (data.length > 9) {
      isBurst = data[9]; 
    }
    if (data.length > 10) _burstTimeController.text = data[10];
    
    calculateAllowedFrequencyDeviation();
    setState(() {});
  }
  void calculateAllowedFrequencyDeviation() {
    var value = _freqController.text;
    if (value.trim().isEmpty) {
      return;
    }
    try {
      var freq = double.parse(value);
      switch (freqResolution.toLowerCase()) {
        case 'khz':
           freq = freq * 1000;
           break;
        case 'mhz':
           freq = freq * 1000 * 1000;
           break;
        case 'ghz':
           freq = freq * 1000 * 1000 * 1000;
           break;
      }
      var devAllowed = freq * 2 / 1000000;
      _allowedFreqDeviation.text = '$devAllowed';
      setState(() {});
    } catch (e) {
      _allowedFreqDeviation.text = '0';
    }
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
                updateRow(!isNew);
              },
              icon: Icon(isNew ? Icons.add : Icons.save, size: 20),
              label: Text(isNew ? "Create Transmitter" : "Save Changes"),
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

    // 1. Mandatory Fields Section
    
    var txName = _buildTextField(
      controller: _nameController,
      label: "Transmitter Name",
      validator: (val) => (val == null || val.trim().isEmpty) ? "Name required" : null,
      // Make TxID editable even if editing
      readOnly: false,
    );
    children.add(txName);

    // Frequency Row
    frequencyDropDown = FrequencyDropDownMenu(
      setFreqResolution,
      selected: freqResolution,
      key: Key(freqResolution),
    );
    
    var freqText = _buildTextField(
      controller: _freqController,
      label: "Frequency",
      validator: (val) {
        if (val == null || val.trim().isEmpty) return "Frequency required";
        if (double.tryParse(val) == null) return "Must be a number";
        return null;
      },
      onChanged: (val) => calculateAllowedFrequencyDeviation(),
    );
    
    children.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: freqText),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: Padding(
            padding: const EdgeInsets.only(top: 0), // Align with text field
            child: frequencyDropDown
        )),
      ],
    ));

    var power = _buildTextField(
      controller: _powerController,
      label: "Power (dBm)",
      validator: (val) {
        if (val == null || val.trim().isEmpty) return "Power required";
        if (double.tryParse(val) == null) return "Must be a number";
        return null;
      },
    );
    children.add(power);

    // Modulation Section

    modulationDropdown = ModulationDropdown(setModulation, selected: modulation, key: Key(modulation));
    children.add(Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: modulationDropdown
    ));

    if ((modulation == 'PM') || (modulation == 'FM')) {
      var subCarr = _buildTextField(
        controller: _noOfSubCarroersController,
        label: "No Of Subcarriers",
        validator: (val) {
          if (val == null || val.trim().isEmpty) return "Required";
          if (int.tryParse(val) == null) return "Must be integer";
          return null;
        },
      );
      children.add(subCarr);
    }

    var harm = _buildTextField(
      controller: _noOfHarmonicsController,
      label: "No Of Harmonics",
      validator: (val) {
         if (val == null || val.trim().isEmpty) return "Required";
         if (int.tryParse(val) == null) return "Must be integer";
         return null;
      },
    );
    children.add(harm);

    // Autopopulated Section with Toggle
    children.add(Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: const Text("Advanced / Autopopulated", style: TextStyle(fontWeight: FontWeight.w600)),
        initiallyExpanded: _showOthers,
        onExpansionChanged: (val) => setState(() => _showOthers = val),
        childrenPadding: const EdgeInsets.only(top: 8),
        children: [
          _buildTextField(
            controller: _spuriousController, 
            label: "Spurious (dBc)",
            validator: (v) => double.tryParse(v ?? "") == null ? "Invalid number" : null
          ),
          _buildTextField(
             controller: _harmonicsController,
             label: "Harmonics (dBc)",
             validator: (v) => double.tryParse(v ?? "") == null ? "Invalid number" : null
          ),
          _buildTextField(
             controller: _allowedFreqDeviation,
             label: "Allowed Freq Deviation",
             readOnly: true, // Calculated automatically
             fillColor: Colors.grey.shade100,
          ),
          _buildTextField(
             controller: _allowedPowerDeviation,
             label: "Allowed Power Deviation",
             validator: (v) => double.tryParse(v ?? "") == null ? "Invalid number" : null
          ),
           _buildTextField(
             controller: _noOfSubHarmonicsController, // Assuming this is sub-harmonics
             label: "No Of Sub-Harmonics",
             validator: (v) => int.tryParse(v ?? "") == null ? "Invalid integer" : null
          ),
          
          const SizedBox(height: 12),
          const Text("Burst Mode", style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          burstDropdown = BurstModeDropdown(setBurstMode, selected: isBurst, key: Key(isBurst)),
          
          if (isBurst == 'Yes') ...[
             const SizedBox(height: 12),
             _buildTextField(
               controller: _burstTimeController,
               label: "Burst Time",
               validator: (v) => int.tryParse(v ?? "") == null ? "Invalid integer" : null
             ),
          ]
        ],
      ),
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
  void updateRow(bool update) async {
    var clientID = widget.global.clientID;
    var tableName = getTableName(widget.global.tableSelected);
    List<String> values = [];
    
    // Server expects [ID, Name, Freq, Power, Spurious, Harmonics, FreqDev, PowerDev, Mod, IsBurst, BurstTime]
    values.add("0"); // Index 0: ID placeholder
    values.add(_nameController.text); // Index 1: Name
    
    var freq = getFrequency(_freqController.text, freqResolution);
    values.add('${freq.toInt()}'); // 2
    
    values.add(_powerController.text); // 3
    values.add(_spuriousController.text); // 4
    values.add(_harmonicsController.text); // 5
    values.add(_allowedFreqDeviation.text); // 6
    values.add(_allowedPowerDeviation.text); // 7
    values.add(modulation); // 8
    values.add(isBurst); // 9
    values.add(_burstTimeController.text); // 10
    
    // Note: SubCarriers/Harmonics counts are excluded as they are not in SpecTx update handler
    var ok = false;
    if (update) {
      ok = await sendUpdateRequest(clientID, tableName, values,
          primaryKey: widget.global.rowSelected);
    } else {
      ok = await sendAddRequest(clientID, tableName, values);
    }

    if (ok) {
      widget.global.subMode = SubModes.showTables;
      widget.callback();
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
               widget.global.rowSelected.isEmpty ? "Create New Transmitter" : "Edit Transmitter", 
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
}