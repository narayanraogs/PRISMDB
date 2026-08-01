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
              label: Text(isNew ? "Insert" : "Save Changes", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
    generalFields.add(_buildSectionHeader("Basic Information", Icons.info_outline_rounded));
    generalFields.add(_buildTextField(
      controller: _nameController,
      label: "Up Down Converter Name",
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Name cannot be empty";
        }
        return null;
      },
    ));
    children.add(_buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: generalFields)));

    List<Widget> freqFields = [];
    freqFields.add(_buildSectionHeader("Frequencies", Icons.waves_rounded));
    
    inputFrequencyDropDown = FrequencyDropDownMenu(
      setInputFreqResolution,
      key: Key(inputFreqResolution),
      selected: inputFreqResolution,
    );

    freqFields.add(Row(
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
    freqFields.add(const SizedBox(height: 20));

    outputFrequencyDropDown = FrequencyDropDownMenu(
      setOutputFreqResolution,
      key: Key(outputFreqResolution),
      selected: outputFreqResolution,
    );

    freqFields.add(Row(
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
    children.add(_buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: freqFields)));

    List<Widget> powerFields = [];
    powerFields.add(_buildSectionHeader("Power Settings", Icons.bolt_rounded));
    powerFields.add(Row(
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
    powerFields.add(const SizedBox(height: 20));

    powerFields.add(Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: CheckboxListTile(
          title: const Text("Radiated Mode?", style: TextStyle(fontWeight: FontWeight.w500)),
          value: _radiated,
          onChanged: (value) {
            _radiated = value ?? false;
            setState(() {});
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          controlAffinity: ListTileControlAffinity.leading,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ));

    if (_radiated) {
      powerFields.add(const SizedBox(height: 20));
      powerFields.add(Row(
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
    
    children.add(_buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: powerFields)));

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
    values.add('0');
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
                   widget.global.rowSelected.isEmpty ? "Create Up Down Converter" : "Edit Up Down Converter", 
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
