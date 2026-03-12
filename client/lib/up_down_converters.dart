import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/custom_dropdown.dart';
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class UpDownConverters extends StatefulWidget {
  final Global global;
  final VoidCallback callback;

  const UpDownConverters(this.global, this.callback, {super.key});

  @override
  State<UpDownConverters> createState() => StateUpDownConverters();
}

class StateUpDownConverters extends State<UpDownConverters> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _inputFreqController = TextEditingController();
  TextEditingController _outputFreqController = TextEditingController();
  TextEditingController _maxInputCable = TextEditingController();
  TextEditingController _minInputCable = TextEditingController();
  TextEditingController _maxInputRad = TextEditingController(text: '0');
  TextEditingController _minInputRad = TextEditingController(text: '0');
  String inputFreqResolution = 'Hz';
  FrequencyDropDownMenu inputFrequencyDropDown =
      FrequencyDropDownMenu((value) {});
  String outputFreqResolution = 'Hz';
  FrequencyDropDownMenu outputFrequencyDropDown =
      FrequencyDropDownMenu((value) {});
  bool _radiated = false;

  void setInputFreqResolution(String value) {
    inputFreqResolution = value;
  }

  void setOutputFreqResolution(String value) {
    outputFreqResolution = value;
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
          _nameController.text = temp.values[1];
          _inputFreqController.text = temp.values[2];
          inputFreqResolution = 'Hz';
          _outputFreqController.text = temp.values[3];
          outputFreqResolution = 'Hz';
          _maxInputCable.text = temp.values[4];
          _minInputCable.text = temp.values[5];
          _radiated = true;
          _maxInputRad.text = temp.values[6];
          _minInputRad.text = temp.values[7];
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
    inputFrequencyDropDown = FrequencyDropDownMenu(setInputFreqResolution);
    outputFrequencyDropDown = FrequencyDropDownMenu(setOutputFreqResolution);
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

    children.add(_buildTextField(
      controller: _nameController,
      label: "Up Down Converter Name",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Name cannot be empty";
        }
        return null;
      },
    ));

    inputFrequencyDropDown = FrequencyDropDownMenu(
      setInputFreqResolution,
      key: Key(inputFreqResolution),
      selected: inputFreqResolution,
    );
    // inputFrequencyDropDown.setFrequency(inputFreqResolution);

    children.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildTextField(
            controller: _inputFreqController,
            label: "Input Frequency",
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
          child: inputFrequencyDropDown,
        ),
      ],
    ));

    outputFrequencyDropDown = FrequencyDropDownMenu(
      setOutputFreqResolution,
      key: Key(outputFreqResolution),
      selected: outputFreqResolution,
    );
    // outputFrequencyDropDown.setFrequency(outputFreqResolution);

    children.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildTextField(
            controller: _outputFreqController,
            label: "Output Frequency",
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
          child: outputFrequencyDropDown,
        ),
      ],
    ));

    children.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTextField(
            controller: _maxInputCable,
            label: "Max Power Cable",
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "Required";
              if (double.tryParse(value) == null) return "Must be a number";
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTextField(
            controller: _minInputCable,
            label: "Min Power Cable",
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "Required";
              if (double.tryParse(value) == null) return "Must be a number";
              return null;
            },
          ),
        ),
      ],
    ));

    children.add(Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: CheckboxListTile(
          title: const Text("Radiated Mode?"),
          value: _radiated,
          onChanged: (value) {
            _radiated = value ?? false;
            setState(() {});
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          controlAffinity: ListTileControlAffinity.leading,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ));

    if (_radiated) {
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildTextField(
              controller: _maxInputRad,
              label: "Max Power Radiated",
              validator: (value) {
                if (value == null || value.trim().isEmpty) return "Required";
                if (double.tryParse(value) == null) return "Must be a number";
                return null;
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTextField(
              controller: _minInputRad,
              label: "Min Power Radiated",
              validator: (value) {
                if (value == null || value.trim().isEmpty) return "Required";
                if (double.tryParse(value) == null) return "Must be a number";
                return null;
              },
            ),
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
    values.add(_nameController.text);
    var inpFreq = getFrequency(_inputFreqController.text, inputFreqResolution);
    values.add('$inpFreq');
    var outFreq =
        getFrequency(_outputFreqController.text, outputFreqResolution);
    values.add('$outFreq');
    var maxCable = 0.0;
    try {
      maxCable = double.parse(_maxInputCable.text);
    } catch (e) {
      maxCable = 0.0;
    }
    values.add('$maxCable');
    var minCable = 0.0;
    try {
      minCable = double.parse(_minInputCable.text);
    } catch (e) {
      minCable = 0.0;
    }
    values.add('$minCable');
    var maxRad = 0.0;
    try {
      maxRad = double.parse(_maxInputRad.text);
    } catch (e) {
      maxRad = 0.0;
    }
    values.add('$maxRad');
    var minRad = 0.0;
    try {
      minRad = double.parse(_minInputRad.text);
    } catch (e) {
      minRad = 0.0;
    }
    values.add('$minRad');

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
               widget.global.rowSelected.isEmpty ? "Create Up Down Converter" : "Edit Up Down Converter", 
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
