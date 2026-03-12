import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

import 'helper_functions.dart';

class Delete extends StatefulWidget {
  final Global global;
  final VoidCallback callback;

  const Delete(this.global, this.callback, {super.key});

  @override
  State<Delete> createState() => StateDelete();
}

class StateDelete extends State<Delete> {
  List<String> _rxNames = [];
  String _selectedRx = '';
  List<String> _txNames = [];
  String _selectedTx = '';
  List<String> _tpNames = [];
  String _selectedTP = '';
  List<String> _configurations = [];
  String _selectedConfig = '';

  void sendRequest() async {
    try {
      ValueRequest valReq = ValueRequest();
      valReq.id = widget.global.clientID;
      valReq.key = "RxNames";
      var resp = await http.post(
        Uri.parse('http://127.0.0.1:8085/getValues'),
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
        Uri.parse('http://127.0.0.1:8085/getValues'),
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
        Uri.parse('http://127.0.0.1:8085/getValues'),
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
        Uri.parse('http://127.0.0.1:8085/getValues'),
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

  void deleteRxName() async {
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: const Icon(Icons.delete_outline_rounded),
            iconColor: Colors.redAccent,
            title: const Text("Confirm Delete"),
            content: const Text(
                "Once Deleted, Data cannot be recovered\nEnsure Delete is being carried out after backing up the data"),
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text("Delete"),
                onPressed: () async {
                  RenameRequest valReq = RenameRequest();
                  valReq.id = widget.global.clientID;
                  valReq.operation = "Delete";
                  valReq.operationType = "Rx";
                  valReq.oldName = _selectedRx;
                  valReq.newName = "";
                  var resp = await http.post(
                    Uri.parse('http://127.0.0.1:8085/bulkAlter'),
                    headers: <String, String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: jsonEncode(valReq.toJSON()),
                  );
                  if (resp.statusCode == 200) {
                    var temp = Ack.fromJson(
                        jsonDecode(resp.body) as Map<String, dynamic>);
                    if (temp.ok) {
                      showMessage("Receiver Deleted", false);
                      sendRequest();
                    } else {
                      showMessage(temp.message, true);
                      return;
                    }
                  } else {
                    showMessage("Server Returned Negative ACK", true);
                    return;
                  }
                  Navigator.pop(context);
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text("Cancel"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('$e');
      showMessage("Server Failed", true);
    }
  }

  void deleteTxName() async {
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: const Icon(Icons.delete_outline_rounded),
            iconColor: Colors.redAccent,
            title: const Text("Confirm Delete"),
            content: const Text(
                "Once Deleted, Data cannot be recovered\nEnsure Delete is being carried out after backing up the data"),
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text("Delete"),
                onPressed: () async {
                  RenameRequest valReq = RenameRequest();
                  valReq.id = widget.global.clientID;
                  valReq.operation = "Delete";
                  valReq.operationType = "Tx";
                  valReq.oldName = _selectedTx;
                  valReq.newName = "";
                  var resp = await http.post(
                    Uri.parse('http://127.0.0.1:8085/bulkAlter'),
                    headers: <String, String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: jsonEncode(valReq.toJSON()),
                  );
                  if (resp.statusCode == 200) {
                    var temp = Ack.fromJson(
                        jsonDecode(resp.body) as Map<String, dynamic>);
                    if (temp.ok) {
                      showMessage("Transmitter Deleted", false);
                      sendRequest();
                    } else {
                      showMessage(temp.message, true);
                      return;
                    }
                  } else {
                    showMessage("Server Returned Negative ACK", true);
                    return;
                  }
                  Navigator.pop(context);
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text("Cancel"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('$e');
      showMessage("Server Failed", true);
    }
  }

  void deleteTpName() async {
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: const Icon(Icons.delete_outline_rounded),
            iconColor: Colors.redAccent,
            title: const Text("Confirm Delete"),
            content: const Text(
                "Once Deleted, Data cannot be recovered\nEnsure Delete is being carried out after backing up the data"),
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text("Delete"),
                onPressed: () async {
                  RenameRequest valReq = RenameRequest();
                  valReq.id = widget.global.clientID;
                  valReq.operation = "Delete";
                  valReq.operationType = "Tp";
                  valReq.oldName = _selectedTP;
                  valReq.newName = "";
                  var resp = await http.post(
                    Uri.parse('http://127.0.0.1:8085/bulkAlter'),
                    headers: <String, String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: jsonEncode(valReq.toJSON()),
                  );
                  if (resp.statusCode == 200) {
                    var temp = Ack.fromJson(
                        jsonDecode(resp.body) as Map<String, dynamic>);
                    if (temp.ok) {
                      showMessage("Transponder Deleted", false);
                      sendRequest();
                    } else {
                      showMessage(temp.message, true);
                      return;
                    }
                  } else {
                    showMessage("Server Returned Negative ACK", true);
                    return;
                  }
                  Navigator.pop(context);
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text("Cancel"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('$e');
      showMessage("Server Failed", true);
    }
  }

  void deleteConfiguration() async {
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: const Icon(Icons.delete_outline_rounded),
            iconColor: Colors.redAccent,
            title: const Text("Confirm Delete"),
            content: const Text(
                "Once Deleted, Data cannot be recovered\nEnsure Delete is being carried out after backing up the data"),
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text("Delete"),
                onPressed: () async {
                  RenameRequest valReq = RenameRequest();
                  valReq.id = widget.global.clientID;
                  valReq.operation = "Delete";
                  valReq.operationType = "Config";
                  valReq.oldName = _selectedConfig;
                  valReq.newName = "";
                  var resp = await http.post(
                    Uri.parse('http://127.0.0.1:8085/bulkAlter'),
                    headers: <String, String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: jsonEncode(valReq.toJSON()),
                  );
                  if (resp.statusCode == 200) {
                    var temp = Ack.fromJson(
                        jsonDecode(resp.body) as Map<String, dynamic>);
                    if (temp.ok) {
                      showMessage("Configuration Deleted", false);
                      sendRequest();
                    } else {
                      showMessage(temp.message, true);
                      return;
                    }
                  } else {
                    showMessage("Server Returned Negative ACK", true);
                    return;
                  }
                  Navigator.pop(context);
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text("Cancel"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('$e');
      showMessage("Server Failed", true);
    }
  }

  Widget getRxDeleteCard() {
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
              const Text(
                "Tables Affected:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text("SpecRx"),
              const Text("SpecRxTM"),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: deleteRxName,
                label: const Text("Delete"),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget getTxDeleteCard() {
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
              const Text(
                "Tables Affected:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text("SpecTx"),
              const Text("SpecTxHarmonics"),
              const Text("SpecTxSubCarriers"),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: deleteTxName,
                label: const Text("Delete"),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget getTpDeleteCard() {
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
              const Text(
                "Tables Affected:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text("SpecTransponder"),
              const Text("SpecTransponderRanging"),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: deleteTpName,
                label: const Text("Delete"),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget getConfigDeleteCard() {
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
                onPressed: deleteConfiguration,
                label: const Text("Delete"),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
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
          getRxDeleteCard(),
          getTxDeleteCard(),
          getTpDeleteCard(),
          getConfigDeleteCard(),
        ],
      ),
    );
  }
}
