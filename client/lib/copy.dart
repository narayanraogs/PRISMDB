import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

import 'helper_functions.dart';

class Copy extends StatefulWidget {
  final Global global;
  final VoidCallback callback;

  const Copy(this.global, this.callback, {super.key});

  @override
  State<Copy> createState() => StateCopy();
}

class StateCopy extends State<Copy> {
  List<String> _rxNames = [];
  String _selectedRx = '';
  List<String> _txNames = [];
  String _selectedTx = '';
  List<String> _tpNames = [];
  String _selectedTP = '';
  List<String> _configurations = [];
  String _selectedConfig = '';
  final TextEditingController _rxController = TextEditingController();
  final TextEditingController _txController = TextEditingController();
  final TextEditingController _tpController = TextEditingController();
  final TextEditingController _configController = TextEditingController();

  void sendRequest() async {
    try {
      ValueRequest valReq = ValueRequest();
      valReq.id = widget.global.clientID;
      valReq.key = "RxNames";
      var resp = await http.post(
        Uri.parse('${Uri.base.origin}/getValues'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(valReq.toJSON()),
      );
      if (resp.statusCode == 200) {
        var temp = ValueResponse.fromJson(
            jsonDecode(resp.body) as Map<String, dynamic>);
        if (temp.ok) {
          _rxNames = [];
          _rxNames.addAll(temp.values);
          _selectedRx = _rxNames.isEmpty ? '' : _rxNames.first;
        } else {
          showMessage(temp.message, true);
          return;
        }
      } else {
        showMessage("Server Returned Negative ACK", true);
        return;
      }

      valReq = ValueRequest();
      valReq.id = widget.global.clientID;
      valReq.key = "TxNames";
      resp = await http.post(
        Uri.parse('${Uri.base.origin}/getValues'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(valReq.toJSON()),
      );
      if (resp.statusCode == 200) {
        var temp = ValueResponse.fromJson(
            jsonDecode(resp.body) as Map<String, dynamic>);
        if (temp.ok) {
          _txNames = [];
          _txNames.addAll(temp.values);
          _selectedTx = _txNames.isEmpty ? '' : _txNames.first;
        } else {
          showMessage(temp.message, true);
          return;
        }
      } else {
        showMessage("Server Returned Negative ACK", true);
        return;
      }

      valReq = ValueRequest();
      valReq.id = widget.global.clientID;
      valReq.key = "TpNames";
      resp = await http.post(
        Uri.parse('${Uri.base.origin}/getValues'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(valReq.toJSON()),
      );
      if (resp.statusCode == 200) {
        var temp = ValueResponse.fromJson(
            jsonDecode(resp.body) as Map<String, dynamic>);
        if (temp.ok) {
          _tpNames = [];
          _tpNames.addAll(temp.values);
          _selectedTP = _tpNames.isEmpty ? '' : _tpNames.first;
        } else {
          showMessage(temp.message, true);
          return;
        }
      } else {
        showMessage("Server Returned Negative ACK", true);
        return;
      }

      valReq = ValueRequest();
      valReq.id = widget.global.clientID;
      valReq.key = "ConfigNames";
      resp = await http.post(
        Uri.parse('${Uri.base.origin}/getValues'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(valReq.toJSON()),
      );
      if (resp.statusCode == 200) {
        var temp = ValueResponse.fromJson(
            jsonDecode(resp.body) as Map<String, dynamic>);
        if (temp.ok) {
          _configurations = [];
          _configurations.addAll(temp.values);
          _selectedConfig =
          _configurations.isEmpty ? '' : _configurations.first;
        } else {
          showMessage(temp.message, true);
          return;
        }
      } else {
        showMessage("Server Returned Negative ACK", true);
        return;
      }
    } on Exception catch (e) {
      debugPrint('$e');
      showMessage("Server Failed", true);
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    sendRequest();
  }

  Widget getExistingReceiverDropdown() {
    List<DropdownMenuItem<String>> items = [];
    for (var it in _rxNames) {
      var item = DropdownMenuItem<String>(
        value: it,
        child: Text(it),
      );
      items.add(item);
    }

    return DropdownButtonFormField<String>(
      items: items,
      value: _selectedRx,
      decoration: const InputDecoration(helperText: "Rx Names"),
      onChanged: (value) {
        _selectedRx = value ?? '';
        setState(() {});
      },
    );
  }

  Widget getExistingTransmitterDropdown() {
    List<DropdownMenuItem<String>> items = [];
    for (var it in _txNames) {
      var item = DropdownMenuItem<String>(
        value: it,
        child: Text(it),
      );
      items.add(item);
    }

    return DropdownButtonFormField<String>(
      items: items,
      value: _selectedTx,
      decoration: const InputDecoration(helperText: "Tx Names"),
      onChanged: (value) {
        _selectedTx = value ?? '';
        setState(() {});
      },
    );
  }

  Widget getExistingTransponderDropdown() {
    List<DropdownMenuItem<String>> items = [];
    for (var it in _tpNames) {
      var item = DropdownMenuItem<String>(
        value: it,
        child: Text(it),
      );
      items.add(item);
    }

    return DropdownButtonFormField<String>(
      items: items,
      value: _selectedTP,
      decoration: const InputDecoration(helperText: "Transponder Names"),
      onChanged: (value) {
        _selectedTP = value ?? '';
        setState(() {});
      },
    );
  }

  Widget getExistingConfigurationDropdown() {
    List<DropdownMenuItem<String>> items = [];
    for (var it in _configurations) {
      var item = DropdownMenuItem<String>(
        value: it,
        child: Text(it),
      );
      items.add(item);
    }

    return DropdownButtonFormField<String>(
      items: items,
      value: _selectedConfig,
      decoration: const InputDecoration(helperText: "Configurations"),
      onChanged: (value) {
        _selectedConfig = value ?? '';
        setState(() {});
      },
    );
  }

  void copyRxName() async {
    try {
      RenameRequest valReq = RenameRequest();
      valReq.id = widget.global.clientID;
      valReq.operation = "Copy";
      valReq.operationType = "Rx";
      valReq.oldName = _selectedRx;
      valReq.newName = _rxController.text;
      var resp = await http.post(
        Uri.parse('${Uri.base.origin}/bulkAlter'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(valReq.toJSON()),
      );
      if (resp.statusCode == 200) {
        var temp = Ack.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
        if (temp.ok) {
          showMessage("Receiver Copied", false);
          sendRequest();
        } else {
          showMessage(temp.message, true);
          return;
        }
      } else {
        showMessage("Server Returned Negative ACK", true);
        return;
      }
    } catch (e) {
      debugPrint('$e');
      showMessage("Server Failed", true);
    }
  }

  void copyTxName() async {
    try {
      RenameRequest valReq = RenameRequest();
      valReq.id = widget.global.clientID;
      valReq.operation = "Copy";
      valReq.operationType = "Tx";
      valReq.oldName = _selectedTx;
      valReq.newName = _txController.text;
      var resp = await http.post(
        Uri.parse('${Uri.base.origin}/bulkAlter'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(valReq.toJSON()),
      );
      if (resp.statusCode == 200) {
        var temp = Ack.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
        if (temp.ok) {
          showMessage("Transmitter Copied", false);
          sendRequest();
        } else {
          showMessage(temp.message, true);
          return;
        }
      } else {
        showMessage("Server Returned Negative ACK", true);
        return;
      }
    } catch (e) {
      debugPrint('$e');
      showMessage("Server Failed", true);
    }
  }

  void copyTpName() async {
    try {
      RenameRequest valReq = RenameRequest();
      valReq.id = widget.global.clientID;
      valReq.operation = "Copy";
      valReq.operationType = "Tp";
      valReq.oldName = _selectedTP;
      valReq.newName = _tpController.text;
      var resp = await http.post(
        Uri.parse('${Uri.base.origin}/bulkAlter'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(valReq.toJSON()),
      );
      if (resp.statusCode == 200) {
        var temp = Ack.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
        if (temp.ok) {
          showMessage("Transponder Copied", false);
          sendRequest();
        } else {
          showMessage(temp.message, true);
          return;
        }
      } else {
        showMessage("Server Returned Negative ACK", true);
        return;
      }
    } catch (e) {
      debugPrint('$e');
      showMessage("Server Failed", true);
    }
  }

  void copyConfiguration() async {
    try {
      RenameRequest valReq = RenameRequest();
      valReq.id = widget.global.clientID;
      valReq.operation = "Copy";
      valReq.operationType = "Config";
      valReq.oldName = _selectedConfig;
      valReq.newName = _configController.text;
      var resp = await http.post(
        Uri.parse('${Uri.base.origin}/bulkAlter'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(valReq.toJSON()),
      );
      if (resp.statusCode == 200) {
        var temp = Ack.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
        if (temp.ok) {
          showMessage("Configuration Copied", false);
          sendRequest();
        } else {
          showMessage(temp.message, true);
          return;
        }
      } else {
        showMessage("Server Returned Negative ACK", true);
        return;
      }
    } catch (e) {
      debugPrint('$e');
      showMessage("Server Failed", true);
    }
  }

  Widget getRxCopyCard() {
    return SizedBox(
      height: 350,
      width: 400,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const Text("Receiver"),
              const Divider(),
              getExistingReceiverDropdown(),
              TextFormField(
                controller: _rxController,
                decoration: const InputDecoration(helperText: "New Name"),
              ),
              const Text(
                "Tables Affected:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text("SpecRx"),
              const Text("SpecRxTM"),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: copyRxName,
                label: const Text("Copy"),
                icon: const Icon(
                  Icons.copy_all,
                  color: Colors.blue,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget getTxCopyCard() {
    return SizedBox(
      height: 350,
      width: 400,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const Text("Transmitter"),
              const Divider(),
              getExistingTransmitterDropdown(),
              TextFormField(
                controller: _txController,
                decoration: const InputDecoration(helperText: "New Name"),
              ),
              const Text(
                "Tables Affected:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text("SpecTx"),
              const Text("SpecTxHarmonics"),
              const Text("SpecTxSubCarriers"),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: copyTxName,
                label: const Text("Copy"),
                icon: const Icon(
                  Icons.copy_all,
                  color: Colors.blue,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget getTpCopyCard() {
    return SizedBox(
      height: 350,
      width: 400,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const Text("Transponder"),
              const Divider(),
              getExistingTransponderDropdown(),
              TextFormField(
                controller: _tpController,
                decoration: const InputDecoration(helperText: "New Name"),
              ),
              const Text(
                "Tables Affected:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text("SpecTransponder"),
              const Text("SpecTransponderRanging"),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: copyTpName,
                label: const Text("Copy"),
                icon: const Icon(
                  Icons.copy_all,
                  color: Colors.blue,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget getConfigCopyCard() {
    return SizedBox(
      height: 350,
      width: 400,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const Text("Configuration"),
              const Divider(),
              getExistingConfigurationDropdown(),
              TextFormField(
                controller: _configController,
                decoration: const InputDecoration(helperText: "New Name"),
              ),
              const Text(
                "Tables Affected:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text("Configuration"),
              const Text("Tests"),
              const Text("UplinkLoss"),
              const Text("DownlinkLoss"),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: copyConfiguration,
                label: const Text("Copy"),
                icon: const Icon(
                  Icons.copy_all,
                  color: Colors.blue,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(
        children: [
          getRxCopyCard(),
          getTxCopyCard(),
          getTpCopyCard(),
          getConfigCopyCard(),
        ],
      ),
    );
  }
}
