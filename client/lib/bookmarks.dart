

import 'package:flutter/material.dart';
import 'package:prism_db_editor/add_test_phase.dart';
import 'package:prism_db_editor/auto_generate_frequencies.dart';
import 'package:prism_db_editor/delete.dart';
import 'package:prism_db_editor/device_ip.dart';
import 'package:prism_db_editor/downlink_loss_upload.dart';
import 'package:prism_db_editor/manual_frequencies.dart';
import 'package:prism_db_editor/rename.dart';
import 'package:prism_db_editor/select_test_phase.dart';
import 'package:prism_db_editor/uplink_loss_upload.dart';
import 'package:prism_db_editor/variables.dart';

import 'copy.dart';

class Bookmarks extends StatefulWidget {
  final Global global;
  final VoidCallback callback;

  const Bookmarks(this.global, this.callback, {super.key});

  @override
  State<Bookmarks> createState() => StateBookmarks();
}

class StateBookmarks extends State<Bookmarks> {
  String _subMode = '';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          flex: 1,
          child: ListView(
            children: [
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Text("Test Phase"),
                  Expanded(child: Divider()),
                ],
              ),
              TextButton(
                onPressed: () {
                  _subMode = "SelectPhase";
                  setState(() {});
                },
                child: const Text("Select Test Phase"),
              ),
              TextButton(
                onPressed: () {
                  _subMode = "CreatePhase";
                  setState(() {});
                },
                child: const Text("Create Test Phase"),
              ),
              Text(''),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Text("Losses"),
                  Expanded(child: Divider()),
                ],
              ),
              TextButton(
                onPressed: () {
                  _subMode = "UplinkLoss";
                  setState(() {});
                },
                child: const Text("Update Uplink Losses"),
              ),
              TextButton(
                onPressed: () {
                  _subMode = "DownlinkLoss";
                  setState(() {});
                },
                child: const Text("Update Downlink Losses"),
              ),
              Text(''),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Text("Devices"),
                  Expanded(child: Divider()),
                ],
              ),
              TextButton(
                onPressed: () {
                  _subMode = "DeviceIPs";
                  setState(() {});
                },
                child: Text(
                  "Update Device IP",
                ),
              ),
              Text(''),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Text("Cable Calibration"),
                  Expanded(child: Divider()),
                ],
              ),
              TextButton(
                onPressed: () {
                  _subMode = "AutoGenerate";
                  setState(() {});
                },
                child: const Text("Auto Generate"),
              ),
              TextButton(
                onPressed: () {
                  _subMode = "ManualFrequencies";
                  setState(() {});
                },
                child: const Text("Add Manually"),
              ),
              const Text(''),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Text("Alter Database"),
                  Expanded(child: Divider()),
                ],
              ),
              TextButton(
                onPressed: () {
                  _subMode = "Rename";
                  setState(() {});
                },
                child: const Text("Rename"),
              ),
              TextButton(
                onPressed: () {
                  _subMode = "Copy";
                  setState(() {});
                },
                child: const Text("Copy"),
              ),
              TextButton(
                onPressed: () {
                  _subMode = "Delete";
                  setState(() {});
                },
                child: const Text("Delete"),
              ),
              const Divider(),
            ],
          ),
        ),
        const VerticalDivider(),
        Expanded(
          flex: 4,
          child: getSecondChild(),
        ),
      ],
    );
  }

  Widget getSecondChild() {
    var subMode = _subMode.toLowerCase();
    switch (subMode) {
      case "selectphase":
        return SelectTestPhase(widget.global, changeMode);
      case "createphase":
        return AddTestPhase(widget.global, changeMode);
      case "autogenerate":
        return AutoGenerateFrequencies(widget.global, changeMode);
      case "manualfrequencies":
        return ManualFrequencies(widget.global, changeMode);
      case "deviceips":
        return DeviceIP(widget.global, changeMode);
      case "uplinkloss":
        return UpLinkLossUpload(widget.global, changeMode);
      case "downlinkloss":
        return DownLinkLossUpload(widget.global, changeMode);
      case "rename":
        return Rename(widget.global, changeMode);
      case "copy":
        return Copy(widget.global, changeMode);
      case "delete":
        return Delete(widget.global, changeMode);
      default:
        return Text(
          "Select Action on Left",
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        );
    }
  }

  void changeMode() {
    setState(() {});
  }
}
