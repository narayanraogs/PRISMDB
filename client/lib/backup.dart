import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

import 'helper_functions.dart';

class Backup extends StatefulWidget {
  final Global global;
  final VoidCallback callback;

  const Backup(this.global, this.callback, {super.key});

  @override
  State<Backup> createState() => StateBackup();
}

class StateBackup extends State<Backup> {
  bool _backedUp = false;

  void sendRequest() async {
    ClientID db = ClientID();
    db.id = widget.global.clientID;
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8085/backup'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(db.toJSON()),
      );

      if (response.statusCode == 200) {
        var ack =
            Ack.fromJson(jsonDecode(response.body) as Map<String, dynamic>);

        if (ack.ok) {
          _backedUp = true;
          showMessage("Backup Completed", false);
        } else {
          showMessage(ack.message, true);
        }
        setState(() {});
      } else {
        showMessage("Server Returned Negative ACK", true);
      }
    } on Exception catch (e) {
      debugPrint('$e');
      showMessage("Server Failed", true);
    }
  }

  @override
  Widget build(BuildContext context) {
    String message = '';
    if (_backedUp) {
      message = "Backup Completed";
    }
    return Center(
      child: SizedBox(
          height: 300,
          
          child: Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'Backup Database',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const Divider(),
                  const Spacer(),
                  Text(message),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      sendRequest();
                    },
                    label: const Text("Backup Database"),
                    icon: const Icon(
                      Icons.sync_sharp,
                      color: Colors.blue,
                    ),
                  )
                ],
              ),
            ),
          )),
    );
  }
}
