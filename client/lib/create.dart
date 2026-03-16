import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/custom_dropdown.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

import 'helper_functions.dart';

class Create extends StatefulWidget {
  final Global global;
  final VoidCallback callback;

  const Create(this.global, this.callback, {super.key});

  @override
  State<Create> createState() => StateCreate();
}

class StateCreate extends State<Create> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController dbName = TextEditingController(
    text: '/home/csrspdev/prism/db/sample.db',
  );

  final TextEditingController noOfRxController = TextEditingController(
    text: '0',
  );
  final TextEditingController noOfTxController = TextEditingController(
    text: '0',
  );
  final TextEditingController noOfTpController = TextEditingController(
    text: '0',
  );
  final TextEditingController noOfPlController = TextEditingController(
    text: '0',
  );
  final TextEditingController noOfConfigController = TextEditingController(
    text: '0',
  );

  List<TextEditingController> rxNames = [];
  List<TextEditingController> rxFreqs = [];
  List<String> rxFreqUnits = [];
  List<ModulationDropdown> rxModulations = [];
  List<String> rxSelModulation = [];

  List<TextEditingController> txNames = [];
  List<TextEditingController> txFreqs = [];
  List<String> txFreqUnits = [];
  List<TextEditingController> txPowers = [];
  List<ModulationDropdown> txModulations = [];
  List<String> txSelModulation = [];

  List<TextEditingController> tpNames = [];
  List<String> tpRxNameSelected = [];
  List<String> tpTxNameSelected = [];

  List<TextEditingController> plNames = [];
  List<TextEditingController> plFreqs = [];
  List<String> plFreqUnits = [];
  List<TextEditingController> plPeakPowers = [];
  List<TextEditingController> plAveragePowers = [];

  List<TextEditingController> configNames = [];
  List<String> configTypes = [];
  List<String> configRxNameSelected = [];
  List<String> configTxNameSelected = [];
  List<String> configTpNameSelected = [];
  List<String> configPlNameSelected = [];
  List<String> configPlResolutionModes = [];

  String? _integerValidator(String? value) {
    if (value == null || value.isEmpty) return "Value has to be an integer";
    try {
      int.parse(value);
    } catch (e) {
      return "Value has to be an integer";
    }
    return null;
  }

  String? _optionalIntegerValidator(String? value) {
    if (value == null || value.isEmpty) return null; // empty is OK, treated as 0
    try {
      int.parse(value);
    } catch (e) {
      return "Value has to be an integer";
    }
    return null;
  }

  String? _stringValidator(String? value) {
    if (value == null || value.isEmpty) return "Value cannot be empty";
    return null;
  }

  String? _doubleValidator(String? value) {
    if (value == null || value.isEmpty)
      return "Value has to be a floating point number";
    try {
      double.parse(value);
    } catch (e) {
      return "Value has to be a floating point number";
    }
    return null;
  }

  double _convertFrequencyToHz(double value, String unit) {
    switch (unit) {
      case 'kHz':
        return value * 1e3;
      case 'MHz':
        return value * 1e6;
      case 'GHz':
        return value * 1e9;
      default:
        return value; // Hz
    }
  }

  void _syncControllers<T>(
    String countText,
    List<T> listToSync,
    void Function() createNew,
    void Function() removeLast,
  ) {
    int targetCount = int.tryParse(countText) ?? 0;
    while (listToSync.length < targetCount) {
      createNew();
    }
    while (listToSync.length > targetCount) {
      removeLast();
    }
    setState(() {});
  }

  void createNewRxController() {
    rxNames.add(TextEditingController());
    rxFreqs.add(TextEditingController());
    rxFreqUnits.add('MHz');
    rxSelModulation.add("PM");
    int index = rxSelModulation.length - 1;
    rxModulations.add(
      ModulationDropdown((value) => rxSelModulation[index] = value),
    );
  }

  void removeRxAt(int index) {
    rxNames.removeAt(index);
    rxFreqs.removeAt(index);
    rxFreqUnits.removeAt(index);
    rxModulations.removeAt(index);
    rxSelModulation.removeAt(index);
    noOfRxController.text = rxNames.length.toString();
    sanetizeConfigValues();
  }

  void removeRxController() {
    removeRxAt(rxNames.length - 1);
  }

  void createNewTxController() {
    txNames.add(TextEditingController());
    txFreqs.add(TextEditingController());
    txFreqUnits.add('MHz');
    txPowers.add(TextEditingController());
    txSelModulation.add("PM");
    int index = txSelModulation.length - 1;
    txModulations.add(
      ModulationDropdown((value) => txSelModulation[index] = value),
    );
  }

  void removeTxAt(int index) {
    txNames.removeAt(index);
    txFreqs.removeAt(index);
    txFreqUnits.removeAt(index);
    txPowers.removeAt(index);
    txModulations.removeAt(index);
    txSelModulation.removeAt(index);
    noOfTxController.text = txNames.length.toString();
    sanetizeConfigValues();
  }

  void removeTxController() {
    removeTxAt(txNames.length - 1);
  }

  void createNewTpController() {
    tpNames.add(TextEditingController());
    tpRxNameSelected.add("");
    tpTxNameSelected.add("");
  }

  void removeTpAt(int index) {
    tpNames.removeAt(index);
    tpRxNameSelected.removeAt(index);
    tpTxNameSelected.removeAt(index);
    noOfTpController.text = tpNames.length.toString();
    sanetizeConfigValues();
  }

  void removeTpController() {
    removeTpAt(tpNames.length - 1);
  }

  void createNewPlController() {
    plNames.add(TextEditingController());
    plFreqs.add(TextEditingController());
    plFreqUnits.add('MHz');
    plPeakPowers.add(TextEditingController());
    plAveragePowers.add(TextEditingController());
  }

  void removePlAt(int index) {
    plNames.removeAt(index);
    plFreqs.removeAt(index);
    plFreqUnits.removeAt(index);
    plPeakPowers.removeAt(index);
    plAveragePowers.removeAt(index);
    noOfPlController.text = plNames.length.toString();
    sanetizeConfigValues();
  }

  void removePlController() {
    removePlAt(plNames.length - 1);
  }

  void createNewConfigController() {
    configNames.add(TextEditingController());
    configTypes.add("Rx");
    configRxNameSelected.add("");
    configTxNameSelected.add("");
    configTpNameSelected.add("");
    configPlNameSelected.add("");
    configPlResolutionModes.add("Normal");
  }

  void removeConfigAt(int index) {
    configNames.removeAt(index);
    configTypes.removeAt(index);
    configRxNameSelected.removeAt(index);
    configTxNameSelected.removeAt(index);
    configTpNameSelected.removeAt(index);
    configPlNameSelected.removeAt(index);
    configPlResolutionModes.removeAt(index);
  }

  void removeConfigController() {
    removeConfigAt(configNames.length - 1);
  }

  void sendRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    CreateRequest req = CreateRequest();
    req.dbPath = dbName.text;

    req.rxNames = rxNames.map((e) => e.text).toList();
    req.rxFrequencies = List.generate(rxFreqs.length, (i) {
      double val = double.tryParse(rxFreqs[i].text) ?? 0.0;
      return _convertFrequencyToHz(val, rxFreqUnits[i]);
    });
    req.rxModulation = rxSelModulation;

    req.txNames = txNames.map((e) => e.text).toList();
    req.txFrequencies = List.generate(txFreqs.length, (i) {
      double val = double.tryParse(txFreqs[i].text) ?? 0.0;
      return _convertFrequencyToHz(val, txFreqUnits[i]);
    });
    req.txPowers = txPowers.map((e) => double.tryParse(e.text) ?? 0.0).toList();
    req.txModulation = txSelModulation;

    req.tpNames = tpNames.map((e) => e.text).toList();
    req.tpRxNames = tpRxNameSelected;
    req.tpTxNames = tpTxNameSelected;

    req.plNames = plNames.map((e) => e.text).toList();
    req.plFrequencies = List.generate(plFreqs.length, (i) {
      double val = double.tryParse(plFreqs[i].text) ?? 0.0;
      return _convertFrequencyToHz(val, plFreqUnits[i]);
    });
    req.plPeakPowers =
        plPeakPowers.map((e) => double.tryParse(e.text) ?? 0.0).toList();
    req.plAveragePowers =
        plAveragePowers.map((e) => double.tryParse(e.text) ?? 0.0).toList();

    req.configNames = configNames.map((e) => e.text).toList();
    req.configTypes = configTypes;
    req.configRxNames = configRxNameSelected;
    req.configTxNames = configTxNameSelected;
    req.configTPNames = configTpNameSelected;
    req.configPlNames = configPlNameSelected;
    req.configPlResolutionModes = configPlResolutionModes;

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8085/autoPopulate'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(req.toJSON()),
      );

      if (response.statusCode == 200) {
        var ack = Ack.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        showMessage(ack.message, !ack.ok);
        if (ack.ok) {
          widget.callback();
        }
      } else {
        showMessage("Server connection failed", true);
      }
    } catch (e) {
      showMessage(e.toString(), true);
    }
  }

  void showMessage(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void sanetizeConfigValues() {
    for (int i = 0; i < configNames.length; i++) {
      if (!rxNames.map((e) => e.text).contains(configRxNameSelected[i])) {
        configRxNameSelected[i] = "";
      }
      if (!txNames.map((e) => e.text).contains(configTxNameSelected[i])) {
        configTxNameSelected[i] = "";
      }
      if (!tpNames.map((e) => e.text).contains(configTpNameSelected[i])) {
        configTpNameSelected[i] = "";
      }
      if (!plNames.map((e) => e.text).contains(configPlNameSelected[i])) {
        configPlNameSelected[i] = "";
      }
    }
  }

  Widget _buildFlatCard({
    required Widget child,
    double width = 280,
    double? height = 320,
  }) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(padding: const EdgeInsets.all(12.0), child: child),
    );
  }

  Widget _buildAddRemoveButtons({
    required String label,
    required VoidCallback onAdd,
    required VoidCallback? onRemove,
  }) {
    return Row(
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.blue.withValues(alpha: 0.1),
            foregroundColor: Colors.blue,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(fontSize: 13),
          ),
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 16),
          label: Text("Add $label"),
        ),
        const SizedBox(width: 8),
        if (onRemove != null)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
            onPressed: onRemove,
            icon: const Icon(Icons.remove, size: 16),
            label: const Text("Remove Last"),
          ),
      ],
    );
  }

  InputDecoration _buildFlatInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        borderRadius: BorderRadius.circular(8.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0, bottom: 16.0, left: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildCountField(
    String label,
    TextEditingController controller,
    void Function() onChange,
  ) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16.0, bottom: 16.0),
      child: TextFormField(
        controller: controller,
        validator: _integerValidator,
        onChanged: (val) {
          onChange();
        },
        decoration: _buildFlatInputDecoration(
          label,
        ).copyWith(prefixIcon: const Icon(Icons.numbers, size: 18)),
      ),
    );
  }

  Widget _buildOptionalCountField(
    String label,
    TextEditingController controller,
    void Function() onChange,
  ) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16.0, bottom: 16.0),
      child: TextFormField(
        controller: controller,
        validator: _optionalIntegerValidator,
        onChanged: (val) {
          onChange();
        },
        decoration: _buildFlatInputDecoration(
          label,
        ).copyWith(
          prefixIcon: const Icon(Icons.numbers, size: 18),
          hintText: "0",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    sanetizeConfigValues();

    return Form(
      key: _formKey,
      child: Container(
        color: Colors.grey.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Database Section
              _buildSectionHeader("Database Configuration"),
              _buildFlatCard(
                width: 400,
                height: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Database Path & Name",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: dbName,
                      validator: _stringValidator,
                      decoration: _buildFlatInputDecoration(
                        "e.g. ./mydatabase.db",
                      ),
                    ),
                  ],
                ),
              ),

              // Receivers Section
              _buildSectionHeader("Receivers (Rx)"),
              Row(
                children: [
                  _buildCountField(
                    "Rx Count",
                    noOfRxController,
                    () => _syncControllers(
                      noOfRxController.text,
                      rxNames,
                      createNewRxController,
                      removeRxController,
                    ),
                  ),
                  _buildAddRemoveButtons(
                    label: "Rx Card",
                    onAdd: () {
                      setState(() {
                        createNewRxController();
                        noOfRxController.text = rxNames.length.toString();
                      });
                    },
                    onRemove: rxNames.isEmpty
                        ? null
                        : () {
                            setState(() {
                              removeRxController();
                            });
                          },
                  ),
                ],
              ),
              if (rxNames.isNotEmpty)
                Wrap(
                  children: List.generate(rxNames.length, (index) {
                    return _buildFlatCard(
                      height: 300,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Rx ${index + 1}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(
                                height: 28,
                                width: 28,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      removeRxAt(index);
                                    });
                                  },
                                  tooltip: "Delete Receiver",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: rxNames[index],
                            validator: _stringValidator,
                            decoration: _buildFlatInputDecoration("Rx Name"),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: rxFreqs[index],
                                  validator: _doubleValidator,
                                  decoration: _buildFlatInputDecoration(
                                    "Frequency",
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  value: rxFreqUnits[index],
                                  decoration: _buildFlatInputDecoration("Unit"),
                                  items: ["Hz", "kHz", "MHz", "GHz"].map((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value, style: const TextStyle(fontSize: 12)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      rxFreqUnits[index] = value ?? "MHz";
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          rxModulations[index],
                        ],
                      ),
                    );
                  }),
                ),

              // Transmitters Section
              _buildSectionHeader("Transmitters (Tx)"),
              Row(
                children: [
                  _buildCountField(
                    "Tx Count",
                    noOfTxController,
                    () => _syncControllers(
                      noOfTxController.text,
                      txNames,
                      createNewTxController,
                      removeTxController,
                    ),
                  ),
                  _buildAddRemoveButtons(
                    label: "Tx Card",
                    onAdd: () {
                      setState(() {
                        createNewTxController();
                        noOfTxController.text = txNames.length.toString();
                      });
                    },
                    onRemove: txNames.isEmpty
                        ? null
                        : () {
                            setState(() {
                              removeTxController();
                            });
                          },
                  ),
                ],
              ),
              if (txNames.isNotEmpty)
                Wrap(
                  children: List.generate(txNames.length, (index) {
                    return _buildFlatCard(
                      height: 340,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Tx ${index + 1}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(
                                height: 28,
                                width: 28,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      removeTxAt(index);
                                    });
                                  },
                                  tooltip: "Delete Transmitter",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: txNames[index],
                            validator: _stringValidator,
                            decoration: _buildFlatInputDecoration("Tx Name"),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: txFreqs[index],
                                  validator: _doubleValidator,
                                  decoration: _buildFlatInputDecoration(
                                    "Frequency",
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  value: txFreqUnits[index],
                                  decoration: _buildFlatInputDecoration("Unit"),
                                  items: ["Hz", "kHz", "MHz", "GHz"].map((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value, style: const TextStyle(fontSize: 12)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      txFreqUnits[index] = value ?? "MHz";
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: txPowers[index],
                            validator: _doubleValidator,
                            decoration: _buildFlatInputDecoration("Power"),
                          ),
                          const SizedBox(height: 8),
                          txModulations[index],
                        ],
                      ),
                    );
                  }),
                ),

              // Transponders Section
              _buildSectionHeader("Transponders (Tp) - Optional"),
              Row(
                children: [
                  _buildOptionalCountField(
                    "Tp Count",
                    noOfTpController,
                    () => _syncControllers(
                      noOfTpController.text,
                      tpNames,
                      createNewTpController,
                      removeTpController,
                    ),
                  ),
                  _buildAddRemoveButtons(
                    label: "Tp Card",
                    onAdd: () {
                      setState(() {
                        createNewTpController();
                        noOfTpController.text = tpNames.length.toString();
                      });
                    },
                    onRemove: tpNames.isEmpty
                        ? null
                        : () {
                            setState(() {
                              removeTpController();
                            });
                          },
                  ),
                ],
              ),
              if (tpNames.isNotEmpty)
                Wrap(
                  children: List.generate(tpNames.length, (index) {
                    List<String> rxList = [""];
                    rxList.addAll(
                      rxNames.map((e) => e.text).where((e) => e.isNotEmpty),
                    );
                    if (!rxList.contains(tpRxNameSelected[index]))
                      tpRxNameSelected[index] = "";

                    List<String> txList = [""];
                    txList.addAll(
                      txNames.map((e) => e.text).where((e) => e.isNotEmpty),
                    );
                    if (!txList.contains(tpTxNameSelected[index]))
                      tpTxNameSelected[index] = "";

                    return _buildFlatCard(
                      height: 290,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Tp ${index + 1}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(
                                height: 28,
                                width: 28,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      removeTpAt(index);
                                    });
                                  },
                                  tooltip: "Delete Transponder",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: tpNames[index],
                            validator: _stringValidator,
                            decoration: _buildFlatInputDecoration("Tp Name"),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: tpRxNameSelected[index],
                            decoration: _buildFlatInputDecoration("Mapped Rx"),
                            items: rxList.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value.isEmpty ? "None" : value, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                tpRxNameSelected[index] = value ?? "";
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: tpTxNameSelected[index],
                            decoration: _buildFlatInputDecoration("Mapped Tx"),
                            items: txList.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value.isEmpty ? "None" : value, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                tpTxNameSelected[index] = value ?? "";
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ),

              // Payloads Section
              _buildSectionHeader("Payloads (Pl) - Optional"),
              Row(
                children: [
                  _buildOptionalCountField(
                    "Pl Count",
                    noOfPlController,
                    () => _syncControllers(
                      noOfPlController.text,
                      plNames,
                      createNewPlController,
                      removePlController,
                    ),
                  ),
                  _buildAddRemoveButtons(
                    label: "Pl Card",
                    onAdd: () {
                      setState(() {
                        createNewPlController();
                        noOfPlController.text = plNames.length.toString();
                      });
                    },
                    onRemove: plNames.isEmpty
                        ? null
                        : () {
                            setState(() {
                              removePlController();
                            });
                          },
                  ),
                ],
              ),
              if (plNames.isNotEmpty)
                Wrap(
                  children: List.generate(plNames.length, (index) {
                    return _buildFlatCard(
                      height: null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Pl ${index + 1}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(
                                height: 28,
                                width: 28,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      removePlAt(index);
                                    });
                                  },
                                  tooltip: "Delete Payload",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: plNames[index],
                            validator: _stringValidator,
                            decoration: _buildFlatInputDecoration("Pl Name"),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: plFreqs[index],
                                  validator: _doubleValidator,
                                  decoration: _buildFlatInputDecoration(
                                    "Frequency",
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  value: plFreqUnits[index],
                                  decoration: _buildFlatInputDecoration("Unit"),
                                  items: ["Hz", "kHz", "MHz", "GHz"].map((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      plFreqUnits[index] = value ?? "MHz";
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: plPeakPowers[index],
                            validator: _doubleValidator,
                            decoration: _buildFlatInputDecoration("Peak Power"),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: plAveragePowers[index],
                            validator: _doubleValidator,
                            decoration: _buildFlatInputDecoration(
                              "Average Power",
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),

              // Configs Section
              _buildSectionHeader("Configurations"),
              Row(
                children: [
                  _buildOptionalCountField(
                    "Config Count",
                    noOfConfigController,
                    () => _syncControllers(
                      noOfConfigController.text,
                      configNames,
                      createNewConfigController,
                      removeConfigController,
                    ),
                  ),
                  _buildAddRemoveButtons(
                    label: "Config Card",
                    onAdd: () {
                      setState(() {
                        createNewConfigController();
                        noOfConfigController.text = configNames.length.toString();
                      });
                    },
                    onRemove: configNames.isEmpty
                        ? null
                        : () {
                            setState(() {
                              removeConfigController();
                              noOfConfigController.text = configNames.length.toString();
                            });
                          },
                  ),
                ],
              ),
              if (configNames.isNotEmpty)
                Wrap(
                  children: List.generate(configNames.length, (index) {
                    List<String> rxList = [""];
                    rxList.addAll(
                      rxNames.map((e) => e.text).where((e) => e.isNotEmpty),
                    );

                    List<String> txList = [""];
                    txList.addAll(
                      txNames.map((e) => e.text).where((e) => e.isNotEmpty),
                    );

                    List<String> tpList = [""];
                    tpList.addAll(
                      tpNames.map((e) => e.text).where((e) => e.isNotEmpty),
                    );

                    List<String> plList = [""];
                    plList.addAll(
                      plNames.map((e) => e.text).where((e) => e.isNotEmpty),
                    );

                    return _buildFlatCard(
                      width: 280,
                      height: null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Config ${index + 1}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(
                                height: 28,
                                width: 28,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      removeConfigAt(index);
                                      noOfConfigController.text = configNames.length.toString();
                                    });
                                  },
                                  tooltip: "Delete Configuration",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: configNames[index],
                            validator: _stringValidator,
                            decoration: _buildFlatInputDecoration("Config Name"),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: configTypes[index],
                            decoration: _buildFlatInputDecoration("Type"),
                            items: ["Rx", "Tx", "Tp", "PL"].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                configTypes[index] = value ?? "";
                              });
                            },
                          ),
                          const SizedBox(height: 8),

                          if (configTypes[index] == "Rx") ...[
                            DropdownButtonFormField<String>(
                              value: rxList.contains(configRxNameSelected[index])
                                  ? configRxNameSelected[index]
                                  : "",
                              decoration: _buildFlatInputDecoration("Mapped Rx"),
                              items: rxList.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value.isEmpty ? "None" : value,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  configRxNameSelected[index] = value ?? "";
                                });
                              },
                            ),
                          ],
                          if (configTypes[index] == "Tx") ...[
                            DropdownButtonFormField<String>(
                              value: txList.contains(configTxNameSelected[index])
                                  ? configTxNameSelected[index]
                                  : "",
                              decoration: _buildFlatInputDecoration("Mapped Tx"),
                              items: txList.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value.isEmpty ? "None" : value,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  configTxNameSelected[index] = value ?? "";
                                });
                              },
                            ),
                          ],
                          if (configTypes[index] == "Tp") ...[
                            DropdownButtonFormField<String>(
                              value: tpList.contains(configTpNameSelected[index])
                                  ? configTpNameSelected[index]
                                  : "",
                              decoration: _buildFlatInputDecoration("Mapped Tp"),
                              items: tpList.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value.isEmpty ? "None" : value,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  configTpNameSelected[index] = value ?? "";
                                });
                              },
                            ),
                          ],
                          if (configTypes[index] == "PL") ...[
                            DropdownButtonFormField<String>(
                              value:
                                  plList.contains(configPlNameSelected[index])
                                      ? configPlNameSelected[index]
                                      : "",
                              decoration: _buildFlatInputDecoration(
                                "Mapped Pl",
                              ),
                              items: plList.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value.isEmpty ? "None" : value,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  configPlNameSelected[index] = value ?? "";
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: configPlResolutionModes[index],
                              decoration: _buildFlatInputDecoration(
                                "Resolution Mode",
                              ),
                              items: ["Normal", "High", "Low"].map((
                                String value,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  configPlResolutionModes[index] =
                                      value ?? "Normal";
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ),

              // Final Save Section
              const SizedBox(height: 64),
              const Divider(),
              const SizedBox(height: 32),
              Center(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 24,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    sendRequest();
                  },
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text("Initialize Database"),
                ),
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
