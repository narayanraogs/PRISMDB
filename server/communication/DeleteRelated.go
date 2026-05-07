package communication

import (
	"database/sql"
	"prismDB/utils"
	"strings"
)

func DeleteRow(db *sql.DB, tableName string, primaryKey string) utils.Ack {
	tableName = strings.ToLower(tableName)
	switch tableName {
	case "spectx":
		return deleteSpecTx(db, primaryKey)
	case "spectxharmonics":
		return deleteSpecTxHarmonics(db, primaryKey)
	case "spectxsubcarriers":
		return deleteSpecTxSubCarriers(db, primaryKey)
	case "specrx":
		return deleteSpecRx(db, primaryKey)
	case "specrxtmtc", "specrxtm":
		return deleteSpecRxTMTC(db, primaryKey)
	case "spectp", "spectransponder":
		return deleteSpecTp(db, primaryKey)
	case "spectpranging", "spectransponderranging":
		return deleteSpecTpRng(db, primaryKey)
	case "testphases":
		return deleteTestPhases(db, primaryKey)
	case "uplinkloss":
		return deleteUplinkLoss(db, primaryKey)
	case "downlinkloss":
		return deleteDownlinkLoss(db, primaryKey)
	case "devices":
		return deleteDevices(db, primaryKey)
	case "deviceprofile":
		return deleteDeviceProfile(db, primaryKey)
	case "obwpowerprofile", "downlinkpowerprofile":
		return deleteDownlinkPowerProfile(db, primaryKey)
	case "frequencyprofile":
		return deleteFrequencyProfile(db, primaryKey)
	case "powerprofile":
		return deletePowerProfile(db, primaryKey)
	case "spectrumsettings", "spectrumprofile":
		return deleteSpectrumProfile(db, primaryKey)
	case "tmprofile":
		return deleteTMProfile(db, primaryKey)
	case "tsmconfigurations":
		return deleteTSMConfiguration(db, primaryKey)
	case "cablecalibrationfrequencies", "lossmeasurementfrequencies":
		return deleteLossMeasurementFrequencies(db, primaryKey)
	case "updownconverter":
		return deleteUpDownConverter(db, primaryKey)
	case "configurations":
		return deleteConfigurations(db, primaryKey)
	case "tests":
		return deleteTests(db, primaryKey)
	case "specpl":
		return deleteSpecPL(db, primaryKey)
	case "pulseprofile":
		return deletePulseProfile(db, primaryKey)
	case "trmprofile":
		return deleteTRMProfile(db, primaryKey)
	}

	return utils.Ack{
		OK:      false,
		Message: "Unknown Table: " + tableName,
	}
}

func deleteSpecTx(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	query := "Delete from SpecTx where TxName like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete SpecTx Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Tx " + primaryKey + " Deleted"
	return ack
}

func deleteSpecTxHarmonics(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	values := strings.Split(primaryKey, ":::")
	if len(values) < 3 {
		ack.OK = false
		ack.Message = "Invalid Primary Key for SpecTxHarmonics"
		return ack
	}
	query := "Delete from SpecTxHarmonics where TxName like ? and HarmonicType like ? and HarmonicsName like ?"
	_, err := db.Exec(query, values[0], values[1], values[2])
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete SpecTxHarmonics Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Tx Harmonics " + primaryKey + " Deleted"
	return ack
}

func deleteSpecTxSubCarriers(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	values := strings.Split(primaryKey, ":::")
	if len(values) < 2 {
		ack.OK = false
		ack.Message = "Invalid Primary Key for SpecTxSubCarriers"
		return ack
	}
	query := "Delete from SpecTxSubCarriers where TxName like ? and SubCarrierName like ?"
	_, err := db.Exec(query, values[0], values[1])
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete SpecTxSubCarriers Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Tx Sub Carrier " + primaryKey + " Deleted"
	return ack
}

func deleteSpecRx(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	query := "Delete from SpecRx where RxName like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete SpecRx Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Receiver " + primaryKey + " Deleted"
	return ack
}

func deleteSpecRxTMTC(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	query := "Delete from SpecRxTMTC where RxName like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete SpecRxTMTC Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Receiver TM " + primaryKey + " Deleted"
	return ack
}

func deleteSpecTp(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	query := "Delete from SpecTp where TpName like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete SpecTp Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Transponder " + primaryKey + " Deleted"
	return ack
}

func deleteSpecTpRng(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	temp := strings.Split(primaryKey, ":::")
	if len(temp) < 2 {
		ack.OK = false
		ack.Message = "Invalid Primary Key for SpecTpRanging"
		return ack
	}
	query := "Delete from SpecTpRanging where TpName like ? and RangingName = ?"
	_, err := db.Exec(query, temp[0], temp[1])
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete SpecTpRanging Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Transponder Ranging " + primaryKey + " Deleted"
	return ack
}

func deleteTestPhases(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	query := "Select count(*) from TestPhases where Name like ? and Selected = 1"
	rows, err := db.Query(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Check TestPhases Row: " + err.Error()
		return ack
	}

	// Helper to read int since we can't use ReadHelpers here easily without refactor
	// Or just scan manually
	var sel int
	if rows.Next() {
		rows.Scan(&sel)
	}
	rows.Close()

	if sel > 0 {
		ack.OK = false
		ack.Message = "Cannot delete a Selected TestPhase"
		return ack
	}

	query = "Delete from TestPhases where Name like ?"
	_, err = db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete TestPhases Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Test Phase " + primaryKey + " Deleted"
	return ack
}

func deleteDownlinkLoss(db *sql.DB, primaryKey string) utils.Ack {
	var temp = strings.Split(primaryKey, ":::")
	var ack utils.Ack
	if len(temp) < 2 {
		ack.OK = false
		ack.Message = "Invalid Primary Key"
		return ack
	}

	query := "Delete from DownlinkLoss where ConfigName like ? and TestPhaseName like ?"
	_, err := db.Exec(query, temp[0], temp[1])
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete DownlinkLoss Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "DownlinkLoss Deleted"
	return ack
}

func deleteUplinkLoss(db *sql.DB, primaryKey string) utils.Ack {
	var temp = strings.Split(primaryKey, ":::")
	var ack utils.Ack
	if len(temp) < 2 {
		ack.OK = false
		ack.Message = "Invalid Primary Key"
		return ack
	}

	query := "Delete from UplinkLoss where ConfigName like ? and TestPhaseName like ?"
	_, err := db.Exec(query, temp[0], temp[1])
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete UplinkLoss Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "UplinkLoss Deleted"
	return ack
}

func deleteDevices(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack

	query := "Delete from Devices where DeviceName like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete Devices Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Device " + primaryKey + " Deleted"
	return ack
}

func deleteDeviceProfile(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack

	query := "Delete from DeviceProfile where DeviceProfileName like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete DeviceProfile Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "DeviceProfile " + primaryKey + " Deleted"
	return ack
}

func deleteDownlinkPowerProfile(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack

	query := "Delete from DownlinkPowerProfile where Name like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete DownlinkPowerProfile Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "DownlinkPowerProfile " + primaryKey + " Deleted"
	return ack
}

func deleteFrequencyProfile(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack

	query := "Delete from FrequencyProfile where Name like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete FrequencyProfile Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Frequency Profile " + primaryKey + " Deleted"
	return ack
}

func deletePowerProfile(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack

	query := "Delete from PowerProfile where Name like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete PowerProfile Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Power Profile " + primaryKey + " Deleted"
	return ack
}

func deleteSpectrumProfile(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	query := "Delete from SpectrumProfile where Name like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete SpectrumProfile Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Spectrum Profile " + primaryKey + " Deleted"
	return ack
}

func deleteTMProfile(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	query := "Delete from TMProfile where Name like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete TMProfile Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "TM Profile " + primaryKey + " Deleted"
	return ack
}

func deleteTSMConfiguration(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	query := "Delete from TSMConfigurations where Name like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete TSMConfigurations Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "TSM Configuration " + primaryKey + " Deleted"
	return ack
}

func deleteLossMeasurementFrequencies(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	query := "Delete from LossMeasurementFrequencies where Description like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete LossMeasurementFrequencies Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Loss Measurement Frequencies " + primaryKey + " Deleted"
	return ack
}

func deleteUpDownConverter(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	query := "Delete from UpDownConverter where Name like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete UpDownConverter Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Up Down Converter " + primaryKey + " Deleted"
	return ack
}

func deleteConfigurations(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	query := "Delete from Configurations where ConfigName like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete Configurations Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Configuration " + primaryKey + " Deleted"
	return ack
}

func deleteTests(db *sql.DB, primaryKey string) utils.Ack {
	temp := strings.Split(primaryKey, ":::")
	var ack utils.Ack
	if len(temp) < 3 {
		ack.OK = false
		ack.Message = "Invalid Primary Key for Tests"
		return ack
	}
	query := "Delete from Tests where ConfigName like ? and TestType like ? and TestCategory like ?"
	_, err := db.Exec(query, temp[0], temp[1], temp[2])
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete Tests Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Test " + primaryKey + " Deleted"
	return ack
}

func deleteSpecPL(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	values := strings.Split(primaryKey, ":::")
	if len(values) < 2 {
		ack.OK = false
		ack.Message = "Invalid Primary Key for SpecPL"
		return ack
	}
	resMode := values[1]
	if strings.EqualFold(resMode, "NULL") {
		resMode = ""
	}
	query := "Delete from SpecPL where ConfigName = ? and COALESCE(ResolutionMode, '') = COALESCE(?, '')"
	_, err := db.Exec(query, values[0], resMode)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete SpecPL Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "SpecPL " + primaryKey + " Deleted"
	return ack
}

func deletePulseProfile(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	query := "Delete from PulseProfile where Name like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete PulseProfile Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "Pulse Profile " + primaryKey + " Deleted"
	return ack
}

func deleteTRMProfile(db *sql.DB, primaryKey string) utils.Ack {
	var ack utils.Ack
	query := "Delete from TRMProfile where Name like ?"
	_, err := db.Exec(query, primaryKey)
	if err != nil {
		ack.OK = false
		ack.Message = "Unable to Delete TRMProfile Row: " + err.Error()
		return ack
	}
	ack.OK = true
	ack.Message = "TRM Profile " + primaryKey + " Deleted"
	return ack
}

// Bulk Delete operations (Optional, kept if needed)
func DeleteBulk(db *sql.DB, deleteType string, name string) utils.Ack {
	switch strings.ToLower(deleteType) {
	case "rx":
		return deleteBulkRx(db, name)
	case "tx":
		return deleteBulkTx(db, name)
	case "tp":
		return deleteBulkTransport(db, name)
	case "config":
		return deleteBulkConfig(db, name)
	}

	return utils.Ack{
		Message: "Unknown Rename Type",
		OK:      false,
	}
}

func deleteBulkRx(db *sql.DB, name string) utils.Ack {
	tx, err := db.Begin()
	if err != nil {
		return utils.Ack{Message: "Transaction Error", OK: false}
	}

	query := "Update Configurations set RxName = NULL where RxName = ?"
	_, err = tx.Exec(query, name)
	if err != nil {
		tx.Rollback()
		return utils.Ack{Message: "Update Config Error", OK: false}
	}

	query = "Delete from SpecRxTMTC where RxName = ?"
	_, err = tx.Exec(query, name)
	if err != nil {
		tx.Rollback()
		return utils.Ack{Message: "Delete SpecRxTMTC Error", OK: false}
	}

	query = "Delete from SpecRx where RxName = ?"
	_, err = tx.Exec(query, name)
	if err != nil {
		tx.Rollback()
		return utils.Ack{Message: "Delete SpecRx Error", OK: false}
	}

	tx.Commit()
	return utils.Ack{Message: "", OK: true}
}

func deleteBulkTx(db *sql.DB, name string) utils.Ack {
	tx, err := db.Begin()
	if err != nil {
		return utils.Ack{Message: "Transaction Error", OK: false}
	}

	query := "Update Configurations set TxName = NULL where TxName = ?"
	_, err = tx.Exec(query, name)
	if err != nil {
		tx.Rollback()
		return utils.Ack{Message: "Update Config Error", OK: false}
	}

	query = "Delete from SpecTxHarmonics where TxName = ?"
	_, err = tx.Exec(query, name)
	if err != nil {
		tx.Rollback()
		return utils.Ack{Message: "Delete Harmonics Error", OK: false}
	}

	query = "Delete from SpecTxSubCarriers where TxName = ?"
	_, err = tx.Exec(query, name)
	if err != nil {
		tx.Rollback()
		return utils.Ack{Message: "Delete SubCarriers Error", OK: false}
	}

	query = "Delete from SpecTx where TxName = ?"
	_, err = tx.Exec(query, name)
	if err != nil {
		tx.Rollback()
		return utils.Ack{Message: "Delete SpecTx Error", OK: false}
	}

	tx.Commit()
	return utils.Ack{Message: "", OK: true}
}

func deleteBulkTransport(db *sql.DB, name string) utils.Ack {
	tx, err := db.Begin()
	if err != nil {
		return utils.Ack{Message: "Transaction Error", OK: false}
	}

	query := "Update Configurations set TpName = NULL where TpName = ?"
	_, err = tx.Exec(query, name)
	if err != nil {
		tx.Rollback()
		return utils.Ack{Message: "Update Config Error", OK: false}
	}

	query = "Delete from SpecTpRanging where TpName = ?"
	_, err = tx.Exec(query, name)
	if err != nil {
		tx.Rollback()
		return utils.Ack{Message: "Delete Ranging Error", OK: false}
	}

	query = "Delete from SpecTp where TpName = ?"
	_, err = tx.Exec(query, name)
	if err != nil {
		tx.Rollback()
		return utils.Ack{Message: "Delete SpecTp Error", OK: false}
	}

	tx.Commit()
	return utils.Ack{Message: "", OK: true}
}

func deleteBulkConfig(db *sql.DB, name string) utils.Ack {
	tx, err := db.Begin()
	if err != nil {
		return utils.Ack{Message: "Transaction Error", OK: false}
	}

	query := "Delete From Configurations where ConfigName = ?"
	_, err = tx.Exec(query, name)
	if err != nil {
		tx.Rollback()
		return utils.Ack{Message: "Delete Config Error", OK: false}
	}

	query = "Delete from Tests where ConfigName = ?"
	_, err = tx.Exec(query, name)
	if err != nil {
		tx.Rollback()
		return utils.Ack{Message: "Delete Tests Error", OK: false}
	}

	query = "Delete from UplinkLoss where ConfigName = ?"
	_, err = tx.Exec(query, name)
	if err != nil {
		tx.Rollback()
		return utils.Ack{Message: "Delete UplinkLoss Error", OK: false}
	}

	query = "Delete from DownlinkLoss where ConfigName = ?"
	_, err = tx.Exec(query, name)
	if err != nil {
		tx.Rollback()
		return utils.Ack{Message: "Delete DownlinkLoss Error", OK: false}
	}

	query = "Delete from SpecPL where ConfigName = ?"
	_, err = tx.Exec(query, name)
	if err != nil {
		tx.Rollback()
		return utils.Ack{Message: "Delete SpecPL Error", OK: false}
	}

	tx.Commit()
	return utils.Ack{Message: "", OK: true}
}
