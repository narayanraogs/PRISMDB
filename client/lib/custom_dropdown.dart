import 'package:flutter/material.dart';

class FrequencyDropDownMenu extends StatefulWidget {
  final ValueSetter<String> callback;
  final String selected;

  const FrequencyDropDownMenu(this.callback, {this.selected = 'Hz', super.key});

  @override
  State<FrequencyDropDownMenu> createState() => StateFrequencyDropDownMenu();
}

class StateFrequencyDropDownMenu extends State<FrequencyDropDownMenu> {
  late String _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.selected;
  }

  @override
  void didUpdateWidget(FrequencyDropDownMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _currentValue = widget.selected;
    }
  }

  List<DropdownMenuItem<String>> getDropDownMenuEntry() {
    List<DropdownMenuItem<String>> tbr = [];
    List<String> freqs = ['Hz', 'kHz', 'MHz', 'GHz'];
    for (var freq in freqs) {
      var item = DropdownMenuItem<String>(
        value: freq,
        child: Text(freq),
      );
      tbr.add(item);
    }
    return tbr;
  }

  @override
  Widget build(BuildContext context) {
    var items = getDropDownMenuEntry();
    return DropdownButton<String>(
      items: items,
      isExpanded: true,
      value: _currentValue,
      hint: const Text("Frequency Resolution"),
      onChanged: (String? value) {
        if (value != null) {
          setState(() {
            _currentValue = value;
          });
          widget.callback(value);
        }
      },
    );
  }
}

class ModulationDropdown extends StatefulWidget {
  final ValueSetter<String> callback;
  final String selected;

  const ModulationDropdown(this.callback, {this.selected = 'BPSK', super.key});

  @override
  State<ModulationDropdown> createState() => StateModulationDropDownMenu();
}

class StateModulationDropDownMenu extends State<ModulationDropdown> {
  late String _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.selected;
  }

  @override
  void didUpdateWidget(ModulationDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _currentValue = widget.selected;
    }
  }

  List<DropdownMenuItem<String>> getDropDownMenuEntry() {
    List<DropdownMenuItem<String>> tbr = [];
    List<String> mods = ['BPSK', 'CDMA', 'FM', 'PM', 'FSK'];
    for (var mod in mods) {
      var item = DropdownMenuItem<String>(
        value: mod,
        child: Text(mod),
      );
      tbr.add(item);
    }
    return tbr;
  }

  @override
  Widget build(BuildContext context) {
    var items = getDropDownMenuEntry();
    return DropdownButtonFormField<String>(
      items: items,
      isExpanded: true,
      value: _currentValue,
      decoration: InputDecoration(
        labelText: "Modulation",
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _currentValue = value;
          });
          widget.callback(value);
        }
      },
    );
  }
}

class BurstModeDropdown extends StatefulWidget {
  final ValueSetter<String> callback;
  final String selected;

  const BurstModeDropdown(this.callback, {this.selected = 'No', super.key});

  @override
  State<BurstModeDropdown> createState() => StateBurstModeDropdown();
}

class StateBurstModeDropdown extends State<BurstModeDropdown> {
  late String _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.selected;
  }

  @override
  void didUpdateWidget(BurstModeDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _currentValue = widget.selected;
    }
  }

  List<DropdownMenuItem<String>> getDropDownMenuEntry() {
    List<DropdownMenuItem<String>> tbr = [];
    List<String> options = ['No', 'Yes'];
    for (var option in options) {
      var item = DropdownMenuItem<String>(
        value: option,
        child: Text(option),
      );
      tbr.add(item);
    }
    return tbr;
  }

  @override
  Widget build(BuildContext context) {
    var items = getDropDownMenuEntry();
    return DropdownButtonFormField<String>(
      items: items,
      isExpanded: true,
      value: _currentValue,
      decoration: InputDecoration(
        labelText: "Burst Mode",
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _currentValue = value;
          });
          widget.callback(value);
        }
      },
    );
  }
}
