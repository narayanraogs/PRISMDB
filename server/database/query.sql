-- name: GetConfigurationsCount :one
SELECT count(*) FROM "Configurations";

-- name: GetDeviceProfileCount :one
SELECT count(*) FROM "DeviceProfile";

-- name: GetDevicesCount :one
SELECT count(*) FROM "Devices";

-- name: GetDownlinkLossCount :one
SELECT count(*) FROM "DownlinkLoss";

-- name: GetDownlinkPowerProfileCount :one
SELECT count(*) FROM "DownlinkPowerProfile";

-- name: GetFrequencyProfileCount :one
SELECT count(*) FROM "FrequencyProfile";

-- name: GetLossMeasurementFrequenciesCount :one
SELECT count(*) FROM "LossMeasurementFrequencies";

-- name: GetPowerProfileCount :one
SELECT count(*) FROM "PowerProfile";

-- name: GetPulseProfileCount :one
SELECT count(*) FROM "PulseProfile";

-- name: GetSpecPLCount :one
SELECT count(*) FROM "SpecPL";

-- name: GetSpecRxCount :one
SELECT count(*) FROM "SpecRx";

-- name: GetSpecRxTMTCCount :one
SELECT count(*) FROM "SpecRxTMTC";

-- name: GetSpecTpCount :one
SELECT count(*) FROM "SpecTp";

-- name: GetSpecTpRangingCount :one
SELECT count(*) FROM "SpecTpRanging";

-- name: GetSpectrumProfileCount :one
SELECT count(*) FROM "SpectrumProfile";

-- name: GetSpecTxCount :one
SELECT count(*) FROM "SpecTx";

-- name: GetSpecTxHarmonicsCount :one
SELECT count(*) FROM "SpecTxHarmonics";

-- name: GetSpecTxSubCarriersCount :one
SELECT count(*) FROM "SpecTxSubCarriers";

-- name: GetTestPhasesCount :one
SELECT count(*) FROM "TestPhases";

-- name: GetTestsCount :one
SELECT count(*) FROM "Tests";

-- name: GetTMProfileCount :one
SELECT count(*) FROM "TMProfile";

-- name: GetTRMProfileCount :one
SELECT count(*) FROM "TRMProfile";

-- name: GetTSMConfigurationsCount :one
SELECT count(*) FROM "TSMConfigurations";

-- name: GetUpDownConverterCount :one
SELECT count(*) FROM "UpDownConverter";

-- name: GetUplinkLossCount :one
SELECT count(*) FROM "UplinkLoss";

-- From ReadSingleValue.go

-- name: GetSpecTxModulation :one
SELECT "ModulationScheme" FROM "SpecTx" WHERE "TxName" LIKE ?;

-- name: GetSpecRxModulation :one
SELECT "ModulationScheme" FROM "SpecRx" WHERE "RxName" LIKE ?;

-- name: GetConfigType :one
SELECT "ConfigType" FROM "Configurations" WHERE "ConfigName" LIKE ?;

-- name: GetSelectedTestPhaseName :one
SELECT "Name" FROM "TestPhases" WHERE "Selected" = 1;

-- From LossRelated.go

-- name: GetUplinkLossByTestPhase :many
SELECT * FROM "UplinkLoss" WHERE "TestPhaseName" LIKE ?;

-- name: InsertUplinkLoss :exec
INSERT INTO "UplinkLoss" ("ConfigName", "TestPhaseName", "Profile") VALUES (?, ?, ?);

-- name: DeleteUplinkLossByTestPhase :exec
DELETE FROM "UplinkLoss" WHERE "TestPhaseName" LIKE ?;

-- name: GetDownlinkLossByTestPhase :many
SELECT * FROM "DownlinkLoss" WHERE "TestPhaseName" LIKE ?;

-- name: InsertDownlinkLoss :exec
INSERT INTO "DownlinkLoss" ("ConfigName", "TestPhaseName", "Profile") VALUES (?, ?, ?);

-- name: DeleteDownlinkLossByTestPhase :exec
DELETE FROM "DownlinkLoss" WHERE "TestPhaseName" LIKE ?;

-- From DevicesRelated.go

-- name: GetDeviceByID :one
SELECT * FROM "Devices" WHERE "ID" = ?;

-- From CopyRelated.go

-- name: CopySpecRxSource :exec
INSERT INTO "SpecRx" ("RxName", "Frequency", "MaxPower", "TCSubCarrierFrequency", "ModulationScheme", "AcquisitionOffset", "SweepRange", "SweepRate", "TCModIndex", "FrequencyDeviationFM", "CodeRateInMcps")
SELECT ?, s."Frequency", s."MaxPower", s."TCSubCarrierFrequency", s."ModulationScheme", s."AcquisitionOffset", s."SweepRange", s."SweepRate", s."TCModIndex", s."FrequencyDeviationFM", s."CodeRateInMcps"
FROM "SpecRx" AS s WHERE s."RxName" = ?;

-- name: CopySpecRxTMTC :exec
INSERT INTO "SpecRxTMTC" ("RxName", "LockStatusMnemonic", "LockStatusValue", "BSLockStatusMnemonic", "BSLockStatusValue", "AGCMnemonic", "CommandCounterMnemonic", "LoopStressMnemonic")
SELECT ?, "LockStatusMnemonic", "LockStatusValue", "BSLockStatusMnemonic", "BSLockStatusValue", "AGCMnemonic", "CommandCounterMnemonic", "LoopStressMnemonic"
FROM "SpecRxTMTC" AS s WHERE s."RxName" = ?;

-- name: CopyConfigurations :exec
INSERT INTO "Configurations" ("ConfigName", "ConfigType", "RxName", "TxName", "TpName", "TSMConfigurationName", "CortexIFM", "IntermediateFrequency", "ProgrammableAttnUsed", "DeviceProfileName")
SELECT ?, "ConfigType", "RxName", "TxName", "TpName", "TSMConfigurationName", "CortexIFM", "IntermediateFrequency", "ProgrammableAttnUsed", "DeviceProfileName"
FROM "Configurations" AS s WHERE s."ConfigName" = ?;

-- name: CopyTests :exec
INSERT INTO "Tests" ("ConfigName", "TestType", "TestCategory", "ULProfileName", "DLProfileName", "PowerProfileName", "FrequencyProfileName", "DownlinkPowerProfileName", "PulseProfileName", "TRMProfileName", "TMProfileName")
SELECT ?, "TestType", "TestCategory", "ULProfileName", "DLProfileName", "PowerProfileName", "FrequencyProfileName", "DownlinkPowerProfileName", "PulseProfileName", "TRMProfileName", "TMProfileName"
FROM "Tests" AS s WHERE s."ConfigName" = ?;

-- name: CopyDownlinkLossFromConfig :exec
INSERT INTO "DownlinkLoss" ("ConfigName", "TestPhaseName", "Profile")
SELECT ?, s."TestPhaseName", s."Profile"
FROM "DownlinkLoss" AS s WHERE s."ConfigName" = ?;

-- name: CopyUplinkLossFromConfig :exec
INSERT INTO "UplinkLoss" ("ConfigName", "TestPhaseName", "Profile")
SELECT ?, s."TestPhaseName", s."Profile"
FROM "UplinkLoss" AS s WHERE s."ConfigName" = ?;

-- name: CopySpecTx :exec
INSERT INTO "SpecTx" ("TxName", "Frequency", "Power", "Spurious", "Harmonics", "AllowedFrequencyDeviation", "AllowedPowerDevaition", "ModulationScheme", "IsBurst", "BurstTime")
SELECT ?, s."Frequency", s."Power", s."Spurious", s."Harmonics", s."AllowedFrequencyDeviation", s."AllowedPowerDevaition", s."ModulationScheme", s."IsBurst", s."BurstTime"
FROM "SpecTx" AS s WHERE s."TxName" = ?;

-- name: CopySpecTxHarmonics :exec
INSERT INTO "SpecTxHarmonics" ("TxName", "HarmonicsID", "HarmonicType", "HarmonicsName", "Frequency", "TotalLossFromTxToSA")
SELECT ?, s."HarmonicsID", s."HarmonicType", s."HarmonicsName", s."Frequency", s."TotalLossFromTxToSA"
FROM "SpecTxHarmonics" AS s WHERE s."TxName" = ?;

-- name: CopySpecTxSubCarriers :exec
INSERT INTO "SpecTxSubCarriers" ("TxName", "SubCarrierID", "SubCarrierName", "Frequency", "ModIndex", "AllowedModIndexDeviation", "AlwaysPresent", "PeakFrequencyDeviation")
SELECT ?, s."SubCarrierID", s."SubCarrierName", s."Frequency", s."ModIndex", s."AllowedModIndexDeviation", s."AlwaysPresent", s."PeakFrequencyDeviation"
FROM "SpecTxSubCarriers" AS s WHERE s."TxName" = ?;

-- name: CopySpecTp :exec
INSERT INTO "SpecTp" ("TpName", "RxName", "TxName")
SELECT ?, s."RxName", s."TxName"
FROM "SpecTp" AS s WHERE s."TpName" = ?;

-- name: CopySpecTpRanging :exec
INSERT INTO "SpecTpRanging" ("TpName", "RangingID", "RangingName", "ToneFrequency", "UplinkToneMIOnlyRanging", "UplinkToneMISimultaneousCmdAndRanging", "TCMISimultaneousCmdAndRanging", "DownlinkMI", "AllowedDownlinkMIDeviation", "AvailableForCommanding")
SELECT ?, s."RangingID", s."RangingName", s."ToneFrequency", s."UplinkToneMIOnlyRanging", s."UplinkToneMISimultaneousCmdAndRanging", s."TCMISimultaneousCmdAndRanging", s."DownlinkMI", s."AllowedDownlinkMIDeviation", s."AvailableForCommanding"
FROM "SpecTpRanging" AS s WHERE s."TpName" = ?;

-- From DeleteRelated.go

-- name: DeleteSpecTx :exec
DELETE FROM "SpecTx" WHERE "TxName" LIKE ?;

-- name: DeleteSpecTxHarmonics :exec
DELETE FROM "SpecTxHarmonics" WHERE "TxName" LIKE ? AND "HarmonicType" LIKE ? AND "HarmonicsName" LIKE ?;

-- name: DeleteSpecTxSubCarriers :exec
DELETE FROM "SpecTxSubCarriers" WHERE "TxName" LIKE ? AND "SubCarrierName" LIKE ?;

-- name: DeleteSpecRx :exec
DELETE FROM "SpecRx" WHERE "RxName" LIKE ?;

-- name: DeleteSpecRxTMTC :exec
DELETE FROM "SpecRxTMTC" WHERE "RxName" LIKE ?;

-- name: DeleteSpecTp :exec
DELETE FROM "SpecTp" WHERE "TpName" LIKE ?;

-- name: DeleteSpecTpRanging :exec
DELETE FROM "SpecTpRanging" WHERE "TpName" LIKE ? AND "RangingName" = ?;

-- name: DeleteTestPhases :exec
DELETE FROM "TestPhases" WHERE "Name" LIKE ?;

-- name: DeleteUplinkLoss :exec
DELETE FROM "UplinkLoss" WHERE "ConfigName" LIKE ? AND "TestPhaseName" LIKE ?;

-- name: DeleteDownlinkLoss :exec
DELETE FROM "DownlinkLoss" WHERE "ConfigName" LIKE ? AND "TestPhaseName" LIKE ?;

-- name: DeleteDevices :exec
DELETE FROM "Devices" WHERE "DeviceName" LIKE ?;

-- name: DeleteDeviceProfile :exec
DELETE FROM "DeviceProfile" WHERE "DeviceProfileName" LIKE ?;

-- name: DeleteFrequencyProfile :exec
DELETE FROM "FrequencyProfile" WHERE "Name" LIKE ?;

-- name: DeletePowerProfile :exec
DELETE FROM "PowerProfile" WHERE "Name" LIKE ?;

-- name: DeleteSpectrumProfile :exec
DELETE FROM "SpectrumProfile" WHERE "Name" LIKE ?;

-- name: DeleteTMProfile :exec
DELETE FROM "TMProfile" WHERE "Name" LIKE ?;

-- name: DeleteTSMConfigurations :exec
DELETE FROM "TSMConfigurations" WHERE "Name" LIKE ?;

-- name: DeleteUpDownConverter :exec
DELETE FROM "UpDownConverter" WHERE "Name" LIKE ?;

-- name: DeleteConfigurations :exec
DELETE FROM "Configurations" WHERE "ConfigName" LIKE ?;

-- name: DeleteTests :exec
DELETE FROM "Tests" WHERE "ConfigName" LIKE ? AND "TestType" LIKE ? AND "TestCategory" LIKE ?;

-- name: RemoveRxFromConfiguration :exec
UPDATE "Configurations" SET "RxName" = NULL WHERE "RxName" = ?;

-- name: RemoveTxFromConfiguration :exec
UPDATE "Configurations" SET "TxName" = NULL WHERE "TxName" = ?;

-- name: RemoveTpFromConfiguration :exec
UPDATE "Configurations" SET "TpName" = NULL WHERE "TpName" = ?;

-- From InsertRelated.go

-- name: InsertSpecTx :exec
INSERT INTO "SpecTx" ("TxName", "Frequency", "Power", "Spurious", "Harmonics", "AllowedFrequencyDeviation", "AllowedPowerDevaition", "ModulationScheme", "IsBurst", "BurstTime")
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: UpdateSpecTx :exec
UPDATE "SpecTx" SET "TxName" = ?, "Frequency" = ?, "Power" = ?, "Spurious" = ?, "Harmonics" = ?, "AllowedFrequencyDeviation" = ?, "AllowedPowerDevaition" = ?, "ModulationScheme" = ?, "IsBurst" = ?, "BurstTime" = ?
WHERE "TxName" = ?;

-- name: InsertSpecTxHarmonics :exec
INSERT INTO "SpecTxHarmonics" ("TxName", "HarmonicsID", "HarmonicType", "HarmonicsName", "Frequency", "TotalLossFromTxToSA") VALUES (?, ?, ?, ?, ?, ?);

-- name: UpdateSpecTxHarmonics :exec
UPDATE "SpecTxHarmonics" SET "TxName" = ?, "HarmonicsID" = ?, "HarmonicType" = ?, "HarmonicsName" = ?, "Frequency" = ?, "TotalLossFromTxToSA" = ?
WHERE "TxName" = ? AND "HarmonicType" = ? AND "HarmonicsName" = ?;

-- name: InsertSpecTxSubCarriers :exec
INSERT INTO "SpecTxSubCarriers" ("TxName", "SubCarrierID", "SubCarrierName", "Frequency", "ModIndex", "AllowedModIndexDeviation", "AlwaysPresent", "PeakFrequencyDeviation") VALUES (?, ?, ?, ?, ?, ?, ?, ?);

-- name: UpdateSpecTxSubCarriers :exec
UPDATE "SpecTxSubCarriers" SET "TxName" = ?, "SubCarrierID" = ?, "SubCarrierName" = ?, "Frequency" = ?, "ModIndex" = ?, "AllowedModIndexDeviation" = ?, "AlwaysPresent" = ?, "PeakFrequencyDeviation" = ?
WHERE "TxName" = ? AND "SubCarrierName" = ?;

-- name: InsertSpecRx :exec
INSERT INTO "SpecRx" ("RxName", "Frequency", "MaxPower", "TCSubCarrierFrequency", "ModulationScheme", "AcquisitionOffset", "SweepRange", "SweepRate", "TCModIndex", "FrequencyDeviationFM", "CodeRateInMcps") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: UpdateSpecRx :exec
UPDATE "SpecRx" SET "RxName" = ?, "Frequency" = ?, "MaxPower" = ?, "TCSubCarrierFrequency" = ?, "ModulationScheme" = ?, "AcquisitionOffset" = ?, "SweepRange" = ?, "SweepRate" = ?, "TCModIndex" = ?, "FrequencyDeviationFM" = ?, "CodeRateInMcps" = ?
WHERE "RxName" = ?;

-- name: InsertSpecRxTMTC :exec
INSERT INTO "SpecRxTMTC" ("RxName", "LockStatusMnemonic", "LockStatusValue", "BSLockStatusMnemonic", "BSLockStatusValue", "AGCMnemonic", "CommandCounterMnemonic", "LoopStressMnemonic", "TestCommandSet", "TestCommandReset") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: UpdateSpecRxTMTC :exec
UPDATE "SpecRxTMTC" SET "RxName" = ?, "LockStatusMnemonic" = ?, "LockStatusValue" = ?, "BSLockStatusMnemonic" = ?, "BSLockStatusValue" = ?, "AGCMnemonic" = ?, "CommandCounterMnemonic" = ?, "LoopStressMnemonic" = ?, "TestCommandSet" = ?, "TestCommandReset" = ?
WHERE "RxName" = ?;

-- name: InsertSpecTp :exec
INSERT INTO "SpecTp" ("TpName", "RxName", "TxName") VALUES (?, ?, ?);

-- name: UpdateSpecTp :exec
UPDATE "SpecTp" SET "TpName" = ?, "RxName" = ?, "TxName" = ? WHERE "TpName" = ?;

-- name: InsertSpecTpRanging :exec
INSERT INTO "SpecTpRanging" ("TpName", "RangingID", "RangingName", "ToneFrequency", "UplinkToneMIOnlyRanging", "UplinkToneMISimultaneousCmdAndRanging", "TCMISimultaneousCmdAndRanging", "DownlinkMI", "AllowedDownlinkMIDeviation", "AvailableForCommanding") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: UpdateSpecTpRanging :exec
UPDATE "SpecTpRanging" SET "TpName" = ?, "RangingID" = ?, "RangingName" = ?, "ToneFrequency" = ?, "UplinkToneMIOnlyRanging" = ?, "UplinkToneMISimultaneousCmdAndRanging" = ?, "TCMISimultaneousCmdAndRanging" = ?, "DownlinkMI" = ?, "AllowedDownlinkMIDeviation" = ?, "AvailableForCommanding" = ?
WHERE "TpName" = ? AND "RangingName" = ?;

-- name: InsertTestPhases :exec
INSERT INTO "TestPhases" ("Name", "CreationDate", "CreationTime", "Selected") VALUES (?, ?, ?, ?);

-- name: UpdateTestPhases :exec
UPDATE "TestPhases" SET "Name" = ?, "CreationDate" = ?, "CreationTime" = ?, "Selected" = ? WHERE "Name" = ?;

-- name: DeselectAllTestPhases :exec
UPDATE "TestPhases" SET "Selected" = 0;

-- name: UpdateDownlinkLoss :exec
UPDATE "DownlinkLoss" SET "ConfigName" = ?, "TestPhaseName" = ?, "Profile" = ? WHERE "ConfigName" = ? AND "TestPhaseName" = ?;

-- name: UpdateUplinkLoss :exec
UPDATE "UplinkLoss" SET "ConfigName" = ?, "TestPhaseName" = ?, "Profile" = ? WHERE "ConfigName" = ? AND "TestPhaseName" = ?;

-- From RenameRelated.go

-- name: GetConfigIDByRxName :many
SELECT "ID" FROM "Configurations" WHERE "RxName" = ?;

-- name: UpdateConfigurationsRxNameNull :exec
UPDATE "Configurations" SET "RxName" = NULL WHERE "RxName" = ?;

-- name: UpdateSpecRxName :exec
UPDATE "SpecRx" SET "RxName" = ? WHERE "RxName" = ?;

-- name: UpdateSpecRxTMTCName :exec
UPDATE "SpecRxTMTC" SET "RxName" = ? WHERE "RxName" = ?;

-- name: UpdateConfigurationsRxName :exec
UPDATE "Configurations" SET "RxName" = ? WHERE "ID" = ?;

-- name: GetConfigIDByTxName :many
SELECT "ID" FROM "Configurations" WHERE "TxName" = ?;

-- name: UpdateConfigurationsTxNameNull :exec
UPDATE "Configurations" SET "TxName" = NULL WHERE "TxName" = ?;

-- name: UpdateSpecTxName :exec
UPDATE "SpecTx" SET "TxName" = ? WHERE "TxName" = ?;

-- name: UpdateSpecTxHarmonicsTxName :exec
UPDATE "SpecTxHarmonics" SET "TxName" = ? WHERE "TxName" = ?;

-- name: UpdateSpecTxSubCarriersTxName :exec
UPDATE "SpecTxSubCarriers" SET "TxName" = ? WHERE "TxName" = ?;

-- name: UpdateConfigurationsTxName :exec
UPDATE "Configurations" SET "TxName" = ? WHERE "ID" = ?;

-- name: GetConfigIDByTpName :many
SELECT "ID" FROM "Configurations" WHERE "TpName" = ?;

-- name: UpdateConfigurationsTpNameNull :exec
UPDATE "Configurations" SET "TpName" = NULL WHERE "TpName" = ?;

-- name: UpdateSpecTpName :exec
UPDATE "SpecTp" SET "TpName" = ? WHERE "TpName" = ?;

-- name: UpdateSpecTpRangingTpName :exec
UPDATE "SpecTpRanging" SET "TpName" = ? WHERE "TpName" = ?;

-- name: UpdateConfigurationsTpName :exec
UPDATE "Configurations" SET "TpName" = ? WHERE "ID" = ?;

-- name: UpdateConfigurationsConfigName :exec
UPDATE "Configurations" SET "ConfigName" = ? WHERE "ConfigName" = ?;

-- name: UpdateTestsConfigName :exec
UPDATE "Tests" SET "ConfigName" = ? WHERE "ConfigName" = ?;

-- name: UpdateUplinkLossConfigName :exec
UPDATE "UplinkLoss" SET "ConfigName" = ? WHERE "ConfigName" = ?;

-- name: UpdateDownlinkLossConfigName :exec
UPDATE "DownlinkLoss" SET "ConfigName" = ? WHERE "ConfigName" = ?;

-- From RowRelated.go

-- name: GetSpecTxByName :one
SELECT * FROM "SpecTx" WHERE "TxName" LIKE ?;

-- name: GetSpecTxHarmonicsByKey :one
SELECT * FROM "SpecTxHarmonics" WHERE "TxName" LIKE ? AND "HarmonicType" LIKE ? AND "HarmonicsName" LIKE ?;

-- name: GetSpecTxSubCarrierByKey :one
SELECT * FROM "SpecTxSubCarriers" WHERE "TxName" LIKE ? AND "SubCarrierName" LIKE ?;

-- name: GetSpecRxByName :one
SELECT * FROM "SpecRx" WHERE "RxName" LIKE ?;

-- name: GetSpecRxTMTCByName :one
SELECT * FROM "SpecRxTMTC" WHERE "RxName" LIKE ?;

-- name: GetSpecTpByName :one
SELECT * FROM "SpecTp" WHERE "TpName" LIKE ?;

-- name: GetSpecTpRangingByKey :one
SELECT * FROM "SpecTpRanging" WHERE "TpName" LIKE ? AND "RangingName" LIKE ?;

-- name: GetUpDownConverterByName :one
SELECT * FROM "UpDownConverter" WHERE "Name" LIKE ?;

-- name: GetTestPhaseByName :one
SELECT * FROM "TestPhases" WHERE "Name" LIKE ?;

-- name: GetDevicesByName :one
SELECT * FROM "Devices" WHERE "DeviceName" LIKE ?;

-- name: GetDeviceProfileByName :one
SELECT * FROM "DeviceProfile" WHERE "DeviceProfileName" LIKE ?;

-- name: GetFrequencyProfileByName :one
SELECT * FROM "FrequencyProfile" WHERE "Name" LIKE ?;

-- name: GetPowerProfileByName :one
SELECT * FROM "PowerProfile" WHERE "Name" LIKE ?;

-- name: GetSpectrumProfileByName :one
SELECT * FROM "SpectrumProfile" WHERE "Name" LIKE ?;

-- name: GetTMProfileByName :one
SELECT * FROM "TMProfile" WHERE "Name" LIKE ?;

-- name: GetDownlinkLossByKey :one
SELECT * FROM "DownlinkLoss" WHERE "ConfigName" LIKE ? AND "TestPhaseName" LIKE ?;

-- name: GetUplinkLossByKey :one
SELECT * FROM "UplinkLoss" WHERE "ConfigName" LIKE ? AND "TestPhaseName" LIKE ?;

-- name: GetTSMConfigurationsByName :one
SELECT * FROM "TSMConfigurations" WHERE "Name" LIKE ?;

-- name: GetTestByID :one
SELECT * FROM "Tests" WHERE "ID" = ?;

-- name: GetConfigurationByName :one
SELECT * FROM "Configurations" WHERE "ConfigName" LIKE ?;

-- From TableRelated.go (List all)

-- name: ListSpecTx :many
SELECT * FROM "SpecTx";

-- name: ListSpecTxHarmonics :many
SELECT * FROM "SpecTxHarmonics";

-- name: ListSpecTxSubCarriers :many
SELECT * FROM "SpecTxSubCarriers";

-- name: ListSpecRx :many
SELECT * FROM "SpecRx";

-- name: ListSpecRxTMTC :many
SELECT * FROM "SpecRxTMTC";

-- name: ListSpecTp :many
SELECT * FROM "SpecTp";

-- name: ListSpecTpRanging :many
SELECT * FROM "SpecTpRanging";

-- name: ListTestPhases :many
SELECT * FROM "TestPhases";

-- name: ListUplinkLoss :many
SELECT * FROM "UplinkLoss";

-- name: ListDownlinkLoss :many
SELECT * FROM "DownlinkLoss";

-- name: ListDevices :many
SELECT * FROM "Devices";

-- name: ListDeviceProfile :many
SELECT * FROM "DeviceProfile";

-- name: ListFrequencyProfile :many
SELECT * FROM "FrequencyProfile";

-- name: ListPowerProfile :many
SELECT * FROM "PowerProfile";

-- name: ListSpectrumProfile :many
SELECT * FROM "SpectrumProfile";

-- name: ListTMProfile :many
SELECT * FROM "TMProfile";

-- name: ListTSMConfigurations :many
SELECT * FROM "TSMConfigurations";

-- name: ListConfigurations :many
SELECT * FROM "Configurations";

-- name: ListTests :many
SELECT * FROM "Tests";

-- name: ListUpDownConverter :many
SELECT * FROM "UpDownConverter";

-- New Queries for missing CRUD operations

-- Configurations
-- name: InsertConfigurations :exec
INSERT INTO "Configurations" ("ConfigName", "ConfigType", "RxName", "TxName", "TpName", "PayloadName", "TSMConfigurationName", "CortexIFM", "IntermediateFrequency", "ProgrammableAttnUsed", "DeviceProfileName") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: UpdateConfigurations :exec
UPDATE "Configurations" SET "ConfigName" = ?, "ConfigType" = ?, "RxName" = ?, "TxName" = ?, "TpName" = ?, "PayloadName" = ?, "TSMConfigurationName" = ?, "CortexIFM" = ?, "IntermediateFrequency" = ?, "ProgrammableAttnUsed" = ?, "DeviceProfileName" = ? WHERE "ConfigName" = ?;

-- DeviceProfile
-- name: InsertDeviceProfile :exec
INSERT INTO "DeviceProfile" ("DeviceProfileName", "SAName", "VSAName", "PMName", "PPMName", "TSMName", "GTxName", "SGName", "VSGName") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: UpdateDeviceProfile :exec
UPDATE "DeviceProfile" SET "DeviceProfileName" = ?, "SAName" = ?, "VSAName" = ?, "PMName" = ?, "PPMName" = ?, "TSMName" = ?, "GTxName" = ?, "SGName" = ?, "VSGName" = ? WHERE "DeviceProfileName" = ?;

-- Devices
-- name: InsertDevices :exec
INSERT INTO "Devices" ("DeviceName", "DeviceMake", "DeviceType", "IPAddress", "ControlPort", "AlternateControlPort", "ReadPort", "DopplerPort", "TimeoutInMillisecs") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: UpdateDevices :exec
UPDATE "Devices" SET "DeviceName" = ?, "DeviceMake" = ?, "DeviceType" = ?, "IPAddress" = ?, "ControlPort" = ?, "AlternateControlPort" = ?, "ReadPort" = ?, "DopplerPort" = ?, "TimeoutInMillisecs" = ? WHERE "DeviceName" = ?;

-- DownlinkPowerProfile
-- name: ListDownlinkPowerProfile :many
SELECT * FROM "DownlinkPowerProfile";

-- name: GetDownlinkPowerProfileByName :one
SELECT * FROM "DownlinkPowerProfile" WHERE "Name" LIKE ?;

-- name: InsertDownlinkPowerProfile :exec
INSERT INTO "DownlinkPowerProfile" ("Name", "PMChannel", "OccupiedBW") VALUES (?, ?, ?);

-- name: UpdateDownlinkPowerProfile :exec
UPDATE "DownlinkPowerProfile" SET "Name" = ?, "PMChannel" = ?, "OccupiedBW" = ? WHERE "Name" = ?;

-- name: DeleteDownlinkPowerProfile :exec
DELETE FROM "DownlinkPowerProfile" WHERE "Name" LIKE ?;

-- FrequencyProfile
-- name: InsertFrequencyProfile :exec
INSERT INTO "FrequencyProfile" ("Name", "MaxFrequency", "StepSize", "CommandingRequired", "DopplerFile") VALUES (?, ?, ?, ?, ?);

-- name: UpdateFrequencyProfile :exec
UPDATE "FrequencyProfile" SET "Name" = ?, "MaxFrequency" = ?, "StepSize" = ?, "CommandingRequired" = ?, "DopplerFile" = ? WHERE "Name" = ?;

-- LossMeasurementFrequencies
-- name: ListLossMeasurementFrequencies :many
SELECT * FROM "LossMeasurementFrequencies";

-- name: GetLossMeasurementFrequenciesByDescription :one
SELECT * FROM "LossMeasurementFrequencies" WHERE "Description" LIKE ?;

-- name: InsertLossMeasurementFrequencies :exec
INSERT INTO "LossMeasurementFrequencies" ("Description", "Frequency") VALUES (?, ?);

-- name: UpdateLossMeasurementFrequencies :exec
UPDATE "LossMeasurementFrequencies" SET "Description" = ?, "Frequency" = ? WHERE "Description" = ?;

-- name: DeleteLossMeasurementFrequencies :exec
DELETE FROM "LossMeasurementFrequencies" WHERE "Description" LIKE ?;

-- PowerProfile
-- name: InsertPowerProfile :exec
INSERT INTO "PowerProfile" ("Name", "PowerLevels", "NoOfCommandsAtThreshold", "NoOfCommandsAtOtherLevels") VALUES (?, ?, ?, ?);

-- name: UpdatePowerProfile :exec
UPDATE "PowerProfile" SET "Name" = ?, "PowerLevels" = ?, "NoOfCommandsAtThreshold" = ?, "NoOfCommandsAtOtherLevels" = ? WHERE "Name" = ?;

-- PulseProfile
-- name: ListPulseProfile :many
SELECT * FROM "PulseProfile";

-- name: GetPulseProfileByName :one
SELECT * FROM "PulseProfile" WHERE "Name" LIKE ?;

-- name: InsertPulseProfile :exec
INSERT INTO "PulseProfile" ("Name", "TransientON", "IQOn", "AcquisitionTime", "SweepTime", "SweepCount", "FilterType", "FilterBandwidth", "YTop", "ThresholdLevel", "Hysterisis", "PPMTriggerLevel", "PPMReferenceLevel", "PPMYDivision", "PPMChannel") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: UpdatePulseProfile :exec
UPDATE "PulseProfile" SET "Name" = ?, "TransientON" = ?, "IQOn" = ?, "AcquisitionTime" = ?, "SweepTime" = ?, "SweepCount" = ?, "FilterType" = ?, "FilterBandwidth" = ?, "YTop" = ?, "ThresholdLevel" = ?, "Hysterisis" = ?, "PPMTriggerLevel" = ?, "PPMReferenceLevel" = ?, "PPMYDivision" = ?, "PPMChannel" = ? WHERE "Name" = ?;

-- name: DeletePulseProfile :exec
DELETE FROM "PulseProfile" WHERE "Name" LIKE ?;

-- SpecPL
-- name: ListSpecPL :many
SELECT * FROM "SpecPL";

-- name: GetSpecPLByConfig :one
SELECT * FROM "SpecPL" WHERE "ConfigName" LIKE ?;

-- name: GetSpecPLByKey :one
SELECT * FROM "SpecPL" WHERE "ConfigName" = ? AND COALESCE("ResolutionMode", '') = COALESCE(?, '');

-- name: InsertSpecPL :exec
INSERT INTO "SpecPL" ("ConfigName", "ResolutionMode", "OnTime", "CenterFrequency", "UplinkPower", "PeakPower", "PeakPowerTolerance", "AveragePower", "AveragePowerTolerance", "DutyCycle", "DutyCycleTolerance", "PulsePeriod", "PulsePeriodTolerance", "ReplicaPeriod", "ReplicaPeriodTolerance", "PulseWidth", "PulseWidthTolerance", "PulseSeperation", "PulseSeperationTolerance", "RiseTime", "RiseTimeTolerance", "FallTime", "FallTimeTolerance", "AverageTxPower", "AverageTxPowerTolerance", "ChirpBandwidth", "ChirpBandwidthTolerance", "RepetitionRate", "RepetitionRateTolerance", "ReplicaRate", "ReplicaRateTolerance", "FrequencyShift", "FrequencyShiftTolerance", "Droop", "DroopTolerance", "Phase", "PhaseTolerance", "Overshoot", "OvershootTolerance", "ChirpRate", "ChirpRateTolerance", "ChirpRateDeviation", "ChirpRateDeviationTolerance", "Ripple", "RippleTolerance") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: UpdateSpecPL :exec
UPDATE "SpecPL" SET "ConfigName" = ?, "ResolutionMode" = ?, "OnTime" = ?, "CenterFrequency" = ?, "UplinkPower" = ?, "PeakPower" = ?, "PeakPowerTolerance" = ?, "AveragePower" = ?, "AveragePowerTolerance" = ?, "DutyCycle" = ?, "DutyCycleTolerance" = ?, "PulsePeriod" = ?, "PulsePeriodTolerance" = ?, "ReplicaPeriod" = ?, "ReplicaPeriodTolerance" = ?, "PulseWidth" = ?, "PulseWidthTolerance" = ?, "PulseSeperation" = ?, "PulseSeperationTolerance" = ?, "RiseTime" = ?, "RiseTimeTolerance" = ?, "FallTime" = ?, "FallTimeTolerance" = ?, "AverageTxPower" = ?, "AverageTxPowerTolerance" = ?, "ChirpBandwidth" = ?, "ChirpBandwidthTolerance" = ?, "RepetitionRate" = ?, "RepetitionRateTolerance" = ?, "ReplicaRate" = ?, "ReplicaRateTolerance" = ?, "FrequencyShift" = ?, "FrequencyShiftTolerance" = ?, "Droop" = ?, "DroopTolerance" = ?, "Phase" = ?, "PhaseTolerance" = ?, "Overshoot" = ?, "OvershootTolerance" = ?, "ChirpRate" = ?, "ChirpRateTolerance" = ?, "ChirpRateDeviation" = ?, "ChirpRateDeviationTolerance" = ?, "Ripple" = ?, "RippleTolerance" = ? WHERE "ConfigName" = ? AND COALESCE("ResolutionMode", '') = COALESCE(?, '');

-- name: DeleteSpecPL :exec
DELETE FROM "SpecPL" WHERE "ConfigName" = ? AND COALESCE("ResolutionMode", '') = COALESCE(?, '');

-- SpectrumProfile
-- name: InsertSpectrumProfile :exec
INSERT INTO "SpectrumProfile" ("Name", "CenterFrequency", "Span", "RBW", "VBW") VALUES (?, ?, ?, ?, ?);

-- name: UpdateSpectrumProfile :exec
UPDATE "SpectrumProfile" SET "Name" = ?, "CenterFrequency" = ?, "Span" = ?, "RBW" = ?, "VBW" = ? WHERE "Name" = ?;

-- TestPhases (already covered, ensuring complete coverage)

-- Tests
-- name: InsertTests :exec
INSERT INTO "Tests" ("ConfigName", "TestType", "TestCategory", "ULProfileName", "DLProfileName", "PowerProfileName", "FrequencyProfileName", "DownlinkPowerProfileName", "PulseProfileName", "TRMProfileName", "TMProfileName") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: UpdateTests :exec
UPDATE "Tests" SET "ConfigName" = ?, "TestType" = ?, "TestCategory" = ?, "ULProfileName" = ?, "DLProfileName" = ?, "PowerProfileName" = ?, "FrequencyProfileName" = ?, "DownlinkPowerProfileName" = ?, "PulseProfileName" = ?, "TRMProfileName" = ?, "TMProfileName" = ? WHERE "ID" = ?;

-- TMProfile
-- name: InsertTMProfile :exec
INSERT INTO "TMProfile" ("Name", "PreRequisiteTM", "LogTM") VALUES (?, ?, ?);

-- name: UpdateTMProfile :exec
UPDATE "TMProfile" SET "Name" = ?, "PreRequisiteTM" = ?, "LogTM" = ? WHERE "Name" = ?;

-- TRMProfile
-- name: ListTRMProfile :many
SELECT * FROM "TRMProfile";

-- name: GetTRMProfileByName :one
SELECT * FROM "TRMProfile" WHERE "Name" LIKE ?;

-- name: InsertTRMProfile :exec
INSERT INTO "TRMProfile" ("Name", "NoOfTRMs", "TimePerTRMInSecs", "DelayBeforeFirstReadInSecs") VALUES (?, ?, ?, ?);

-- name: UpdateTRMProfile :exec
UPDATE "TRMProfile" SET "Name" = ?, "NoOfTRMs" = ?, "TimePerTRMInSecs" = ?, "DelayBeforeFirstReadInSecs" = ? WHERE "Name" = ?;

-- name: DeleteTRMProfile :exec
DELETE FROM "TRMProfile" WHERE "Name" LIKE ?;

-- TSMConfigurations
-- name: InsertTSMConfiguration :exec
INSERT INTO "TSMConfigurations" ("Name", "UplinkToSC", "IncludePad", "ExcludePad", "UplinkToSA", "UplinkToPM", "TerminateUplink", "DownlinkToSA", "DownlinkToPM", "AttnNumber", "DownlinkToDC", "InputPortName", "SAPortName", "PMPortName", "OutputPortName") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: UpdateTSMConfiguration :exec
UPDATE "TSMConfigurations" SET "Name" = ?, "UplinkToSC" = ?, "IncludePad" = ?, "ExcludePad" = ?, "UplinkToSA" = ?, "UplinkToPM" = ?, "TerminateUplink" = ?, "DownlinkToSA" = ?, "DownlinkToPM" = ?, "AttnNumber" = ?, "DownlinkToDC" = ?, "InputPortName" = ?, "SAPortName" = ?, "PMPortName" = ?, "OutputPortName" = ? WHERE "Name" = ?;

-- UpDownConverter
-- name: InsertUpDownConverter :exec
INSERT INTO "UpDownConverter" ("Name", "InputFrequency", "OutputFrequency", "MaxPowerCable", "MinPowerCable", "MaxPowerRadiated", "MinPowerRadiated") VALUES (?, ?, ?, ?, ?, ?, ?);

-- name: UpdateUpDownConverter :exec
UPDATE "UpDownConverter" SET "Name" = ?, "InputFrequency" = ?, "OutputFrequency" = ?, "MaxPowerCable" = ?, "MinPowerCable" = ?, "MaxPowerRadiated" = ?, "MinPowerRadiated" = ? WHERE "Name" = ?;
