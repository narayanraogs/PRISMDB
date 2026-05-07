import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/custom_dropdown.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class Create extends StatefulWidget {
  final Global global;
  final VoidCallback callback;

  const Create(this.global, this.callback, {super.key});

  @override
  State<Create> createState() => StateCreate();
}

class StateCreate extends State<Create> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _dbKey = GlobalKey();
  final GlobalKey _rxKey = GlobalKey();
  final GlobalKey _txKey = GlobalKey();
  final GlobalKey _tpKey = GlobalKey();
  final GlobalKey _plKey = GlobalKey();
  final GlobalKey _configKey = GlobalKey();

  int _selectedNavIndex = 0;

  void _scrollToSection(GlobalKey key, int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

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

  List<String> deletedRxNames = [];
  List<String> deletedTxNames = [];
  List<String> deletedTpNames = [];
  List<String> deletedPlNames = [];
  List<String> deletedConfigNames = [];

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
    if (rxNames[index].text.isNotEmpty) {
      deletedRxNames.add(rxNames[index].text);
    }
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
    if (txNames[index].text.isNotEmpty) {
      deletedTxNames.add(txNames[index].text);
    }
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
    if (tpNames[index].text.isNotEmpty) {
      deletedTpNames.add(tpNames[index].text);
    }
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
    if (plNames[index].text.isNotEmpty) {
      deletedPlNames.add(plNames[index].text);
    }
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
    configPlResolutionModes.add("");
  }

  void removeConfigAt(int index) {
    if (configNames[index].text.isNotEmpty) {
      deletedConfigNames.add(configNames[index].text);
    }
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

    req.deletedRxNames = deletedRxNames;
    req.deletedTxNames = deletedTxNames;
    req.deletedTpNames = deletedTpNames;
    req.deletedPlNames = deletedPlNames;
    req.deletedConfigNames = deletedConfigNames;

    try {
      final response = await http.post(
        Uri.parse('${Uri.base.origin}/autoPopulate'),
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

  Future<void> _loadExistingCards() async {
    String path = dbName.text;
    if (path.isEmpty) return;

    try {
      final responseReg = await http.post(
        Uri.parse('${Uri.base.origin}/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ID': 'client_create', 'DBName': path, 'Create': false, 'FromConfig': false}),
      );
      if (responseReg.statusCode != 200) {
        showMessage("Failed to connect to db", true);
        return;
      }
      var ack = Ack.fromJson(jsonDecode(responseReg.body));
      if (!ack.ok) {
        showMessage("Failed to open db: ${ack.message}", true);
        return;
      }

      Future<List<RowDetails>> fetchTable(String tableName) async {
        final res = await http.post(
          Uri.parse('${Uri.base.origin}/getTables'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'ID': 'client_create', 'TableName': tableName}),
        );
        if (res.statusCode == 200) {
          var details = TableDisplayDetails.fromJson(jsonDecode(res.body));
          if (details.ok) return details.details;
        }
        return [];
      }

      var rxRows = await fetchTable("SpecRx");
      var txRows = await fetchTable("SpecTx");
      var tpRows = await fetchTable("SpecTp");
      var configRows = await fetchTable("Configurations");
      var plRows = await fetchTable("SpecPL");

      setState(() {
        deletedRxNames.clear();
        deletedTxNames.clear();
        deletedTpNames.clear();
        deletedPlNames.clear();
        deletedConfigNames.clear();

        rxNames.clear(); rxFreqs.clear(); rxFreqUnits.clear(); rxSelModulation.clear(); rxModulations.clear();
        for (var row in rxRows) {
          if (row.details.length < 6) continue;
          rxNames.add(TextEditingController(text: row.details[1]));
          double freq = double.tryParse(row.details[2]) ?? 0;
          rxFreqs.add(TextEditingController(text: (freq / 1e6).toString()));
          rxFreqUnits.add("MHz");
          String mod = row.details[5];
          rxSelModulation.add(mod);
          int index = rxSelModulation.length - 1;
          rxModulations.add(ModulationDropdown((val) => rxSelModulation[index] = val, selected: mod));
        }
        noOfRxController.text = rxNames.length.toString();

        txNames.clear(); txFreqs.clear(); txFreqUnits.clear(); txPowers.clear(); txSelModulation.clear(); txModulations.clear();
        for (var row in txRows) {
          if (row.details.length < 9) continue;
          txNames.add(TextEditingController(text: row.details[1]));
          double freq = double.tryParse(row.details[2]) ?? 0;
          txFreqs.add(TextEditingController(text: (freq / 1e6).toString()));
          txFreqUnits.add("MHz");
          txPowers.add(TextEditingController(text: row.details[3]));
          String mod = row.details[8];
          txSelModulation.add(mod);
          int index = txSelModulation.length - 1;
          txModulations.add(ModulationDropdown((val) => txSelModulation[index] = val, selected: mod));
        }
        noOfTxController.text = txNames.length.toString();

        tpNames.clear(); tpRxNameSelected.clear(); tpTxNameSelected.clear();
        for (var row in tpRows) {
          if (row.details.length < 4) continue;
          tpNames.add(TextEditingController(text: row.details[1]));
          tpRxNameSelected.add(row.details[2] == "NULL" ? "" : row.details[2]);
          tpTxNameSelected.add(row.details[3] == "NULL" ? "" : row.details[3]);
        }
        noOfTpController.text = tpNames.length.toString();

        plNames.clear(); plFreqs.clear(); plFreqUnits.clear(); plPeakPowers.clear(); plAveragePowers.clear();
        Map<String, String> configToPayload = {};
        for(var row in configRows) {
            if(row.details.length >= 7 && row.details[2] == "PL" && row.details[6] != "NULL") {
                configToPayload[row.details[1]] = row.details[6];
            }
        }

        for (var row in plRows) {
          if (row.details.length < 9) continue;
          String configName = row.details[1];
          String payloadName = configToPayload[configName] ?? configName;
          
          if (!plNames.map((e) => e.text).contains(payloadName)) {
            plNames.add(TextEditingController(text: payloadName));
            double freq = double.tryParse(row.details[4]) ?? 0;
            plFreqs.add(TextEditingController(text: (freq / 1e6).toString()));
            plFreqUnits.add("MHz");
            plPeakPowers.add(TextEditingController(text: row.details[6]));
            plAveragePowers.add(TextEditingController(text: row.details[8]));
          }
        }
        noOfPlController.text = plNames.length.toString();

        configNames.clear(); configTypes.clear(); configRxNameSelected.clear(); configTxNameSelected.clear(); configTpNameSelected.clear(); configPlNameSelected.clear(); configPlResolutionModes.clear();
        for (var row in configRows) {
          if (row.details.length < 8) continue;
          configNames.add(TextEditingController(text: row.details[1]));
          configTypes.add(row.details[2]);
          configRxNameSelected.add(row.details[3] == "NULL" ? "" : row.details[3]);
          configTxNameSelected.add(row.details[4] == "NULL" ? "" : row.details[4]);
          configTpNameSelected.add(row.details[5] == "NULL" ? "" : row.details[5]);
          configPlNameSelected.add(row.details[6] == "NULL" ? "" : row.details[6]);
          configPlResolutionModes.add(""); 
        }
        noOfConfigController.text = configNames.length.toString();
        
        showMessage("Loaded existing configurations", false);
      });
    } catch (e) {
      showMessage("Error loading: $e", true);
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
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.0),
      ),
      child: Padding(padding: const EdgeInsets.all(16.0), child: child),
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

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0, bottom: 20.0, left: 8.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 28, color: const Color(0xFF3E2723)),
            const SizedBox(width: 12),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E2723),
              letterSpacing: -0.5,
            ),
          ),
        ],
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

    return Row(
      children: [
        // Sidebar Navigation
        Container(
          width: 240,
          color: Colors.white,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.blue, size: 28),
                    SizedBox(width: 12),
                    Text(
                      "Setup",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  children: [
                    _buildNavItem(0, Icons.storage, "Database", _dbKey),
                    _buildNavItem(1, Icons.settings_input_antenna, "Receivers", _rxKey),
                    _buildNavItem(2, Icons.sensors, "Transmitters", _txKey),
                    _buildNavItem(3, Icons.swap_horiz, "Transponders", _tpKey),
                    _buildNavItem(4, Icons.developer_board, "Payloads", _plKey),
                    _buildNavItem(5, Icons.tune, "Configurations", _configKey),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        sendRequest();
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      "Initialize DB",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Main Content Area
        Expanded(
          child: Form(
            key: _formKey,
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48.0,
                  vertical: 40.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Database Section
                    Column(
                      key: _dbKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          "Database Configuration",
                          icon: Icons.storage_rounded,
                        ),
                        _buildFlatCard(
                          width: double.infinity,
                          height: null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Database Path & Name",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: dbName,
                                validator: _stringValidator,
                                decoration: _buildFlatInputDecoration(
                                  "e.g. ./mydatabase.db",
                                ).copyWith(
                                  prefixIcon: const Icon(
                                    Icons.file_present_rounded,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: _loadExistingCards,
                                  icon: const Icon(Icons.download),
                                  label: const Text(
                                    "Load Existing Database",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Receivers Section
                    Column(
                      key: _rxKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          "Receivers (Rx)",
                          icon: Icons.settings_input_antenna,
                        ),
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
              ],
            ),

                    // Transmitters Section
                    Column(
                      key: _txKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          "Transmitters (Tx)",
                          icon: Icons.sensors,
                        ),
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
              ],
            ),

                    // Transponders Section
                    Column(
                      key: _tpKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          "Transponders (Tp)",
                          icon: Icons.swap_horiz,
                        ),
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
              ],
            ),

                    // Payloads Section
                    Column(
                      key: _plKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          "Payloads (Pl)",
                          icon: Icons.developer_board,
                        ),
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
              ],
            ),

                    // Configurations Section
                    Column(
                      key: _configKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          "Configurations",
                          icon: Icons.tune,
                        ),
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
                              items: ["", "HR", "LR"].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value == "" ? "NULL" : value,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  configPlResolutionModes[index] = value ?? "";
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ),

                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    GlobalKey key,
  ) {
    final isSelected = _selectedNavIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Material(
        color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          onTap: () => _scrollToSection(key, index),
          leading: Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey.shade600,
            size: 20,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          dense: true,
        ),
      ),
    );
  }
}
