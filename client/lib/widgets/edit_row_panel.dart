import 'package:flutter/material.dart';
import 'package:prism_db_editor/spec_transmitter.dart';
import 'package:prism_db_editor/spec_receiver.dart';
import 'package:prism_db_editor/spec_transponder.dart';
import 'package:prism_db_editor/spec_tx_harmonics.dart';
import 'package:prism_db_editor/spec_tx_subcarriers.dart';
import 'package:prism_db_editor/spec_transponder_ranging.dart';
import 'package:prism_db_editor/spec_rx_tm.dart';
import 'package:prism_db_editor/spectrum_settings.dart';
import 'package:prism_db_editor/tm_profile.dart';
import 'package:prism_db_editor/tsm_configurations.dart';
import 'package:prism_db_editor/up_down_converters.dart';
import 'package:prism_db_editor/configurations.dart';
import 'package:prism_db_editor/up_link_losses.dart';
import 'package:prism_db_editor/channel_power_profile.dart';
import 'package:prism_db_editor/add_test_phase.dart';
import 'package:prism_db_editor/cable_calibration_frequencies.dart';
import 'package:prism_db_editor/device_ip.dart';
import 'package:prism_db_editor/spec_payload.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:prism_db_editor/services/api_service.dart';
import 'package:prism_db_editor/widgets/edit_tests.dart';
import 'package:prism_db_editor/widgets/edit_device_profile.dart';
import 'package:prism_db_editor/widgets/edit_generic_profile.dart';
import 'package:prism_db_editor/widgets/edit_trm_profile.dart';
import 'package:prism_db_editor/widgets/loss_wrapper.dart';

class EditRowPanel extends StatefulWidget {
  final String tableName;
  final List<String>? initialRow;
  final List<String> headers;
  final bool isCopy;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const EditRowPanel({
    super.key, 
    required this.tableName, 
    this.initialRow, 
    required this.headers,
    this.isCopy = false,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  State<EditRowPanel> createState() => _EditRowPanelState();
}

class _EditRowPanelState extends State<EditRowPanel> {
  final ApiService _apiService = ApiService();
  final String _clientID = "client_1";
  final _formKey = GlobalKey<FormState>();
  final Map<int, TextEditingController> _controllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (int i = 0; i < widget.headers.length; i++) {
      String initialValue = "";
      if (widget.initialRow != null && i < widget.initialRow!.length) {
        initialValue = widget.initialRow![i];
      }
      _controllers[i] = TextEditingController(text: initialValue);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    List<String> values = [];
    for (int i = 0; i < widget.headers.length; i++) {
      if (widget.headers[i].toLowerCase() == 'id') {
        if (widget.initialRow != null && i < widget.initialRow!.length) {
          values.add(widget.initialRow![i]);
        } else {
          values.add("0");
        }
      } else {
        values.add(_controllers[i]?.text ?? "");
      }
    }

    setState(() => _isLoading = true);

    try {
      bool success = false;
      if (widget.initialRow == null || widget.isCopy) {
        success = await _apiService.addRow(_clientID, widget.tableName, values);
      } else {
        // Use Name (Index 1) as Primary Key for updates, as most tables use Name for lookup
        final String pkValue = widget.initialRow!.length > 1 ? widget.initialRow![1] : widget.initialRow![0];
        success = await _apiService.updateRow(_clientID, widget.tableName, pkValue, values);
      }

      if (success) {
        widget.onComplete();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to save row"), backgroundColor: Colors.red)
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tableName.toLowerCase() == 'spectx') {
      return SpecTransmitter(
        Global(clientID: _clientID)
          ..tableSelected = Tables.specTx
          ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : widget.initialRow![1],
        widget.onComplete,
        initialData: widget.initialRow,
      );
    }

    if (widget.tableName.toLowerCase() == 'specrx') {
      return SpecReceiver(
        Global(clientID: _clientID)
          ..tableSelected = Tables.specRx
          ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : widget.initialRow![1],
        widget.onComplete,
        initialData: widget.initialRow,
      );
    }

    if (widget.tableName.toLowerCase() == 'spectp') {
      return SpecTransponder(
        Global(clientID: _clientID)
          ..tableSelected = Tables.specTransponder
          ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : widget.initialRow![1],
        widget.onComplete,
        initialData: widget.initialRow,
      );
    }

    if (widget.tableName.toLowerCase() == 'spectxharmonics') {
      String selectedRow = '';
      if (widget.initialRow != null && widget.initialRow!.length > 3) {
        selectedRow = '${widget.initialRow![0]}:::${widget.initialRow![2]}:::${widget.initialRow![3]}';
      }
      return SpecTxHarmonics(
        Global(clientID: _clientID)
          ..tableSelected = Tables.specTxHarmonics
          ..rowSelected = widget.isCopy ? '' : selectedRow,
        widget.onComplete,
      );
    }

    if (widget.tableName.toLowerCase() == 'spectxsubcarriers') {
      String selectedRow = '';
      if (widget.initialRow != null && widget.initialRow!.length > 2) {
        selectedRow = '${widget.initialRow![0]}:::${widget.initialRow![2]}';
      }
      return SpecTxSubcarriers(
        Global(clientID: _clientID)
          ..tableSelected = Tables.specTxSubCarriers
          ..rowSelected = widget.isCopy ? '' : selectedRow,
        widget.onComplete,
      );
    }

    if (widget.tableName.toLowerCase() == 'spectpranging') {
      String selectedRow = '';
      if (widget.initialRow != null && widget.initialRow!.length > 2) {
        selectedRow = '${widget.initialRow![0]}:::${widget.initialRow![2]}';
      }
      return SpecTransponderRanging(
        Global(clientID: _clientID)
          ..tableSelected = Tables.specTransponderRanging
          ..rowSelected = widget.isCopy ? '' : selectedRow,
        widget.onComplete,
        initialData: widget.initialRow,
      );
    }

    if (widget.tableName.toLowerCase() == 'specrxtmtc') {
      return SpecRxTM(
        Global(clientID: _clientID)
          ..tableSelected = Tables.specRxTM
          ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : widget.initialRow![0],
        widget.onComplete,
        initialData: widget.initialRow,
      );
    }

    if (widget.tableName.toLowerCase() == 'spectrumsettings') {
      return SpectrumSettings(
        Global(clientID: _clientID)
          ..tableSelected = Tables.spectrumSettings
          ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : widget.initialRow![0],
        widget.onComplete,
      );
    }

    if (widget.tableName.toLowerCase() == 'tmprofile') {
      return TmProfile(
        Global(clientID: _clientID)
          ..tableSelected = Tables.tmProfile
          ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : (widget.initialRow!.length > 1 ? widget.initialRow![1] : widget.initialRow![0]),
        widget.onComplete,
        initialData: widget.initialRow,
      );
    }

    if (widget.tableName.toLowerCase() == 'tsmconfigurations') {
      return TsmConfigurations(
        Global(clientID: _clientID)
          ..tableSelected = Tables.tsmConfigurations
          ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : (widget.initialRow!.length > 1 ? widget.initialRow![1] : widget.initialRow![0]),
        widget.onComplete,
        initialData: widget.initialRow,
      );
    }

    if (widget.tableName.toLowerCase() == 'updownconverter') {
      return UpDownConverters(
        Global(clientID: _clientID)
          ..tableSelected = Tables.upDownConverter
          ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : (widget.initialRow!.length > 1 ? widget.initialRow![1] : widget.initialRow![0]),
        widget.onComplete,
      );
    }

    if (widget.tableName.toLowerCase() == 'configurations') {
      return Configurations(
        Global(clientID: _clientID)
          ..tableSelected = Tables.configurations
          ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : (widget.initialRow!.length > 1 ? widget.initialRow![1] : widget.initialRow![0]),
        widget.onComplete,
        initialData: widget.initialRow,
      );
    }

    if (widget.tableName.toLowerCase() == 'uplinkloss') {
      String selectedRow = '';
      if (widget.initialRow != null && widget.initialRow!.length > 2) {
        selectedRow = '${widget.initialRow![1]}:::${widget.initialRow![2]}';
      }
      return LossWrapper(
        global: Global(clientID: _clientID)
          ..tableSelected = Tables.uplinkLoss
          ..rowSelected = widget.isCopy ? '' : selectedRow,
        callback: widget.onComplete,
      );
    }

    if (widget.tableName.toLowerCase() == 'downlinkloss') {
      String selectedRow = '';
      if (widget.initialRow != null && widget.initialRow!.length > 2) {
        selectedRow = '${widget.initialRow![1]}:::${widget.initialRow![2]}';
      }
      return LossWrapper(
        global: Global(clientID: _clientID)
          ..tableSelected = Tables.downLinkLoss
          ..rowSelected = widget.isCopy ? '' : selectedRow,
        callback: widget.onComplete,
      );
    }

    if (widget.tableName.toLowerCase() == 'specpl') {
      String selectedRow = '';
      if (widget.initialRow != null && widget.initialRow!.length > 2) {
        selectedRow = '${widget.initialRow![1]}:::${widget.initialRow![2]}';
      }
      return SpecPayload(
        Global(clientID: _clientID)
          ..tableSelected = Tables.specPL
          ..rowSelected = widget.isCopy ? '' : selectedRow,
        widget.onComplete,
        initialData: widget.initialRow,
      );
    }

    if (widget.tableName.toLowerCase() == 'obwpower') {
      return OBWPowerProfile(
        Global(clientID: _clientID)
          ..tableSelected = Tables.obwPowerProfile
          ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : (widget.initialRow!.length > 1 ? widget.initialRow![1] : widget.initialRow![0]),
        widget.onComplete,
      );
    }

    if (widget.tableName.toLowerCase() == 'testphase' || widget.tableName.toLowerCase() == 'testphases') {
      return AddTestPhase(
        Global(clientID: _clientID)
          ..tableSelected = Tables.testPhases
          ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : (widget.initialRow!.length > 1 ? widget.initialRow![1] : widget.initialRow![0]),
        widget.onComplete,
        initialData: widget.initialRow,
      );
    }

    if (widget.tableName.toLowerCase() == 'cablecalibration') {
      return CableCalibrationFrequencies(
        Global(clientID: _clientID)
          ..tableSelected = Tables.cableCalibrationFrequencies
          ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : (widget.initialRow!.length > 1 ? widget.initialRow![1] : widget.initialRow![0]),
        widget.onComplete,
      );
    }

    if (widget.tableName.toLowerCase() == 'tests') {
      return EditTests(
        Global(clientID: _clientID)
          ..tableSelected = Tables.tests
          ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : widget.initialRow![0],
        widget.onComplete,
        initialData: widget.initialRow,
      );
    }

    if (widget.tableName.toLowerCase() == 'devices') {
      return DeviceIP(
        Global(clientID: _clientID)
          ..tableSelected = Tables.devices
          ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : (widget.initialRow!.length > 1 ? widget.initialRow![1] : widget.initialRow![0]),
        widget.onComplete,
        initialData: widget.initialRow,
      );
    }

    if (widget.tableName.toLowerCase() == 'deviceprofile') {
      return EditDeviceProfile(
        Global(clientID: _clientID)
          ..tableSelected = Tables.deviceProfile
          ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : (widget.initialRow!.length > 1 ? widget.initialRow![1] : widget.initialRow![0]),
        widget.onComplete,
        initialData: widget.initialRow,
      );
    }



    if (widget.tableName.toLowerCase() == 'trmprofile') {
      return EditTRMProfile(
        Global(clientID: _clientID)
          ..tableSelected = Tables.trmProfile
          ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : (widget.initialRow!.length > 1 ? widget.initialRow![1] : widget.initialRow![0]),
        widget.onComplete,
        initialData: widget.initialRow,
      );
    }

    // List of tables that should use the Generic Profile Editor (Hidden ID, Custom Dropdowns, Units)
    List<String> genericProfileTables = [
      'frequencyprofile',
      'downlinkpowerprofile',
      'powerprofile',
      'pulseprofile',
      'spectrumprofile',
      'lossmeasurementfrequencies'
    ];

    if (genericProfileTables.contains(widget.tableName.toLowerCase())) {
       return EditGenericProfile(
         Global(clientID: _clientID)
           ..tableSelected = _getTableEnum(widget.tableName)
           ..rowSelected = (widget.initialRow == null || widget.isCopy) ? '' : (widget.initialRow!.length > 1 ? widget.initialRow![1] : widget.initialRow![0]), 
         widget.onComplete,
         initialData: widget.initialRow,
         tableName: widget.tableName,
         headers: widget.headers,
       );
    }

    // Generic Table Edit
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildGenericFields(),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
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
                  onPressed: _isLoading ? null : _handleSave,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGenericFields() {
    List<Widget> fields = [];
    for (int i = 0; i < widget.headers.length; i++) {
      if (widget.headers[i].toLowerCase() == 'id') continue;
      fields.add(Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: TextFormField(
          controller: _controllers[i],
          decoration: InputDecoration(
            labelText: widget.headers[i],
            hintText: "Enter ${widget.headers[i]}",
            filled: true,
            fillColor: Colors.grey.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) => (value == null || value.isEmpty) ? "${widget.headers[i]} is required" : null,
        ),
      ));
    }
    return fields;
  }

  Tables _getTableEnum(String tableName) {
     switch(tableName.toLowerCase()) {
       case 'frequencyprofile': return Tables.frequencyProfile;
       case 'downlinkpowerprofile': return Tables.downLinkPowerProfile;
       case 'powerprofile': return Tables.powerProfile;
       case 'pulseprofile': return Tables.pulseProfile;
       case 'trmprofile': return Tables.trmProfile;
       case 'spectrumprofile': return Tables.spectrumProfile;
       case 'lossmeasurementfrequencies': return Tables.lossMeasurementFrequencies;
       default: return Tables.noTable;
     }
  }
}
