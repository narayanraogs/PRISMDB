import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/custom_dropdown.dart';
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class SpecReceiver extends StatefulWidget {
  final Global global;
  final VoidCallback callback;
  final List<String>? initialData;

  const SpecReceiver(this.global, this.callback, {this.initialData, super.key});

  @override
  State<SpecReceiver> createState() => StateSpecReceiver();
}

class StateSpecReceiver extends State<SpecReceiver> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _freqController = TextEditingController();
  TextEditingController _powerController = TextEditingController();
  TextEditingController _tcSubCarFreqController = TextEditingController();
  TextEditingController _acqOffsetController = TextEditingController();
  TextEditingController _sweepRangeController = TextEditingController();
  TextEditingController _sweepRateController = TextEditingController();
  TextEditingController _tcMIController = TextEditingController();
  TextEditingController _freqDevController = TextEditingController();
  TextEditingController _codeRateController = TextEditingController();

  String freqResolution = 'Hz';
  String modulation = 'PM';
  ModulationDropdown modulationDropdown = ModulationDropdown((value) {});
  FrequencyDropDownMenu frequencyDropDown = FrequencyDropDownMenu((value) {});

  void setFreqResolution(String value) {
    freqResolution = value;
    setState(() {});
  }

  void setModulation(String value) {
    modulation = value;
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
          // Schema: [ID, RxName, Frequency, MaxPower, TCSubCarrierFrequency, ModulationScheme, AcquisitionOffset, SweepRange, SweepRate, TCModIndex, FrequencyDeviationFM, CodeRateInMcps]
          _nameController.text = temp.values[1];
          _freqController.text = temp.values[2];
          freqResolution = 'Hz';
          _powerController.text = temp.values[3];
          _tcSubCarFreqController.text = temp.values[4];
          modulation = temp.values[5].toUpperCase();
          _acqOffsetController.text = temp.values[6];
          _sweepRangeController.text = temp.values[7];
          _sweepRateController.text = temp.values[8];
          _tcMIController.text = temp.values[9];
          _freqDevController.text = temp.values[10];
          if (temp.values.length > 11) {
            _codeRateController.text = temp.values[11];
          }
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
    
    if (widget.initialData != null && widget.initialData!.isNotEmpty && widget.global.rowSelected.isNotEmpty) {
      _populateFromInitialData();
    } else {
      sendRequest();
    }
  }

  void _populateFromInitialData() {
    var data = widget.initialData!;
    // Schema: [ID, RxName, Frequency, MaxPower, TCSubCarrierFrequency, ModulationScheme, AcquisitionOffset, SweepRange, SweepRate, TCModIndex, FrequencyDeviationFM, CodeRateInMcps]
    if (data.length > 1) _nameController.text = data[1];
    if (data.length > 2) {
      _freqController.text = data[2];
      freqResolution = 'Hz';
    }
    if (data.length > 3) _powerController.text = data[3];
    if (data.length > 4) _tcSubCarFreqController.text = data[4];
    if (data.length > 5) {
      modulation = data[5].toUpperCase();
    }
    if (data.length > 6) _acqOffsetController.text = data[6];
    if (data.length > 7) _sweepRangeController.text = data[7];
    if (data.length > 8) _sweepRateController.text = data[8];
    if (data.length > 9) _tcMIController.text = data[9];
    if (data.length > 10) _freqDevController.text = data[10];
    if (data.length > 11) _codeRateController.text = data[11];
    setState(() {});
  }

  List<Widget> getChildren(BuildContext context) {
    List<Widget> children = [];

    children.add(_buildTextField(
      controller: _nameController,
      label: "Receiver Name",
      validator: (v) => (v == null || v.trim().isEmpty) ? "Name cannot be empty" : null,
    ));

    children.add(Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildTextField(
            controller: _freqController,
            label: "Frequency",
            validator: (v) => double.tryParse(v ?? "") == null ? "Invalid frequency" : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Unit", style: TextStyle(fontSize: 12, color: Colors.grey)),
              frequencyDropDown = FrequencyDropDownMenu(setFreqResolution, selected: freqResolution, key: Key(freqResolution)),
            ],
          ),
        ),
      ],
    ));

    children.add(_buildTextField(
      controller: _powerController,
      label: "Max Power",
      validator: (v) => double.tryParse(v ?? "") == null ? "Invalid value" : null,
    ));

    children.add(const Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Text("Modulation Scheme", style: TextStyle(fontSize: 14, color: Colors.grey)),
    ));
    children.add(Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: modulationDropdown = ModulationDropdown(setModulation, selected: modulation, key: Key(modulation)),
    ));

    children.add(_buildTextField(
      controller: _tcSubCarFreqController,
      label: "TC Sub-Carrier Frequency",
      validator: (v) => double.tryParse(v ?? "") == null ? "Invalid value" : null,
    ));

    // Conditional Fields based on Modulation
    if (modulation == 'FSK') {
      children.add(_buildTextField(
        controller: _acqOffsetController,
        label: "Acquisition Offset",
        validator: (v) => double.tryParse(v ?? "") == null ? "Invalid value" : null,
      ));
    }

    if (modulation == 'PM') {
      children.add(_buildTextField(
        controller: _sweepRangeController,
        label: "Sweep Range",
        validator: (v) => double.tryParse(v ?? "") == null ? "Invalid value" : null,
      ));

      children.add(_buildTextField(
        controller: _sweepRateController,
        label: "Sweep Rate",
        validator: (v) => double.tryParse(v ?? "") == null ? "Invalid value" : null,
      ));

      children.add(_buildTextField(
        controller: _tcMIController,
        label: "TC Modulation Index",
        validator: (v) => double.tryParse(v ?? "") == null ? "Invalid value" : null,
      ));
    }

    if (modulation == 'FM') {
      children.add(_buildTextField(
        controller: _freqDevController,
        label: "Frequency Deviation FM",
        validator: (v) => double.tryParse(v ?? "") == null ? "Invalid value" : null,
      ));
    }

    if (modulation == 'BPSK' || modulation == 'CDMA') {
      children.add(_buildTextField(
        controller: _codeRateController,
        label: "Code Rate (Mcps)",
        validator: (v) => v!.isNotEmpty && double.tryParse(v) == null ? "Invalid value" : null,
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
          fillColor: Colors.grey.withOpacity(0.04),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget getButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                widget.global.subMode = SubModes.showTables;
                widget.callback();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Cancel"),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  updateRow(widget.global.rowSelected.isNotEmpty);
                }
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(widget.global.rowSelected.isEmpty ? "Create" : "Save Changes"),
            ),
          ),
        ],
      ),
    );
  }

  void updateRow(bool edit) async {
    var clientID = widget.global.clientID;
    var tableName = getTableName(widget.global.tableSelected);
    List<String> values = [];
    
    // Server expects [ID, RxName, Frequency, MaxPower, TCSubCarrierFrequency, ModulationScheme, AcquisitionOffset, SweepRange, SweepRate, TCModIndex, FrequencyDeviationFM, CodeRateInMcps]
    values.add("0"); // Index 0: ID
    values.add(_nameController.text); // Index 1: Name
    
    var freq = getFrequency(_freqController.text, freqResolution);
    values.add('${freq.toInt()}'); // 2
    
    values.add(getDouble(_powerController.text)); // 3
    values.add(getDouble(_tcSubCarFreqController.text)); // 4
    values.add(modulation); // 5
    values.add(getDouble(_acqOffsetController.text)); // 6
    values.add(getDouble(_sweepRangeController.text)); // 7
    values.add(getDouble(_sweepRateController.text)); // 8
    values.add(getDouble(_tcMIController.text)); // 9
    values.add(getDouble(_freqDevController.text)); // 10
    values.add(getDouble(_codeRateController.text)); // 11

    bool ok = false;
    if (edit) {
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
               widget.global.rowSelected.isEmpty ? "Create New Receiver" : "Edit Receiver", 
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
