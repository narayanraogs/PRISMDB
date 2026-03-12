package communication

import (
	"database/sql"
	"fmt"
	"prismDB/utils"
	"strconv"
	"strings"
)

func Validate(conn *sql.DB) utils.ValidationResult {
	var validate utils.ValidationResult
	validate.OK = false
	validate.Message = "To be Implemented"
	validate.SingleTables = make([]utils.SingleTableDetails, 0)

	specTx, ok := validateSpecTx(conn)
	if !ok {
		validate.Message = "Unable to read Spec Tx table"
		return validate
	}
	validate.SingleTables = append(validate.SingleTables, specTx)

	SpecTxHarmonics, ok := validateSpecTxHarmonics(conn)
	if !ok {
		validate.Message = "Unable to read Spec Tx Harmonics table"
		return validate
	}
	validate.SingleTables = append(validate.SingleTables, SpecTxHarmonics)

	SpecTxSubCarriers, ok := validateSpecTxSubCarriers(conn)
	if !ok {
		validate.Message = "Unable to read Spec Tx Sub Carriers table"
		return validate
	}
	validate.SingleTables = append(validate.SingleTables, SpecTxSubCarriers)

	SpecRx, ok := validateSpecRx(conn)
	if !ok {
		validate.Message = "Unable to read Spec Rx table"
		return validate
	}
	validate.SingleTables = append(validate.SingleTables, SpecRx)

	SpecRxTMTC, ok := validateSpecRxTMTC(conn)
	if !ok {
		validate.Message = "Unable to read Spec Rx TM table"
		return validate
	}
	validate.SingleTables = append(validate.SingleTables, SpecRxTMTC)

	SpecTP, ok := validateSpecTp(conn)
	if !ok {
		validate.Message = "Unable to read SpecTp table"
		return validate
	}
	validate.SingleTables = append(validate.SingleTables, SpecTP)

	SpecTPRng, ok := validateSpecTpRanging(conn)
	if !ok {
		validate.Message = "Unable to read SpecTpRanging table"
		return validate
	}
	validate.SingleTables = append(validate.SingleTables, SpecTPRng)

	tps, ok := validateTestPhase(conn)
	if !ok {
		validate.Message = "Unable to read TestPhases table"
		return validate
	}
	validate.SingleTables = append(validate.SingleTables, tps)

	uls, ok := validateUplinkLossTable(conn)
	if !ok {
		validate.Message = "Unable to read UplinkLoss table"
		return validate
	}
	validate.SingleTables = append(validate.SingleTables, uls)

	dls, ok := validateDownlinkLossTable(conn)
	if !ok {
		validate.Message = "Unable to read DownlinkLoss table"
		return validate
	}
	validate.SingleTables = append(validate.SingleTables, dls)

	dev, ok := validateDevices(conn)
	if !ok {
		validate.Message = "Unable to read Device table"
		return validate
	}
	validate.SingleTables = append(validate.SingleTables, dev)

	prof, ok := validateDeviceProfiles(conn)
	if !ok {
		validate.Message = "Unable to read DeviceProfiles table"
		return validate
	}
	validate.SingleTables = append(validate.SingleTables, prof)

	chPowerProf, ok := validateDownlinkPowerProfile(conn)
	if !ok {
		validate.Message = "Unable to read Downlink Power Profile table"
		return validate
	}
	validate.SingleTables = append(validate.SingleTables, chPowerProf)

	freqPower, ok := validateFrequencyProfile(conn)
	if !ok {
		validate.Message = "Unable to read Channel Profile table"
		return validate
	}
	validate.SingleTables = append(validate.SingleTables, freqPower)

	powerProf, ok := validatePowerProfile(conn)
	if !ok {
		validate.Message = "Unable to read Power Profile table"
		return validate
	}
	validate.SingleTables = append(validate.SingleTables, powerProf)

	spec, ok := validateSpectrumProfile(conn)
	if !ok {
		validate.Message = "Unable to read Spectrum Settings table"
		return validate
	}
	validate.SingleTables = append(validate.SingleTables, spec)

	validate.OK = true
	validate.Message = ""
	return validate
}

func validateSpecTx(conn *sql.DB) (utils.SingleTableDetails, bool) {
	var single utils.SingleTableDetails
	single.TableName = "SpecTx"
	query := "Select * from SpecTx"
	rows, err := conn.Query(query)
	if err != nil {
		return single, false
	}
	values, ok := readSpecTx(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	single.Items = len(values)
	single.Errors = 0
	single.Warnings = 0

	return single, true
}

func validateSpecTxHarmonics(conn *sql.DB) (utils.SingleTableDetails, bool) {
	//Warining Conditions:
	//1. Total Loss from Tx to SA is zero
	var single utils.SingleTableDetails
	single.TableName = "SpecTxHarmonics"

	var errors = 0
	var warnings = 0
	var items = 0

	query := "Select Count(*) from SpecTxHarmonics where TotalLossFromTxToSA = 0"
	rows, err := conn.Query(query)
	if err != nil {
		return single, false
	}
	loss, ok := readSingleInt(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	warnings = warnings + loss
	if loss > 0 {
		single.WarningList = append(single.WarningList, fmt.Sprintf("%d items have Total Loss from Tx to SA as 0", loss))
	}
	query = "Select Count(*) from SpecTxHarmonics"
	rows, err = conn.Query(query)
	if err != nil {
		return single, false
	}
	items, ok = readSingleInt(rows)
	if !ok {
		return single, false
	}
	rows.Close()

	single.Items = items
	single.Errors = errors
	single.Warnings = warnings

	return single, true
}

func validateSpecTxSubCarriers(conn *sql.DB) (utils.SingleTableDetails, bool) {
	//Error Conditions:
	//1. Frequency Cannot be Zero
	//2. Peak Frequency Deviation Cannot be zero for FSK
	var single utils.SingleTableDetails
	single.TableName = "SpecTxSubCarriers"
	query := "Select * from SpecTx"
	rows, err := conn.Query(query)
	if err != nil {
		return single, false
	}
	values, ok := readSpecTx(rows)
	if !ok {
		return single, false
	}
	rows.Close()

	var errors = 0
	var warnings = 0
	var items = 0

	for _, value := range values {
		if strings.EqualFold(value.modulationScheme, "pm") {
			query = "Select Count(*) from SpecTxSubCarriers where TxName like ? and Frequency = 0"
			rows, err = conn.Query(query, value.txName)
			if err != nil {
				return single, false
			}
			zeros, ok := readSingleInt(rows)
			if !ok {
				return single, false
			}
			rows.Close()
			errors = errors + zeros
			if zeros > 0 {
				single.ErrorList = append(single.ErrorList, fmt.Sprintf("Tx %s (PM): %d subcarriers have 0 Frequency", value.txName, zeros))
			}
		}
		if strings.EqualFold(value.modulationScheme, "fsk") {
			query = "Select Count(*) from SpecTxSubCarriers where TxName like ? and PeakFrequencyDeviation = 0"
			rows, err = conn.Query(query, value.txName)
			if err != nil {
				return single, false
			}
			zeros, ok := readSingleInt(rows)
			if !ok {
				return single, false
			}
			rows.Close()
			errors = errors + zeros
			if zeros > 0 {
				single.ErrorList = append(single.ErrorList, fmt.Sprintf("Tx %s (FSK): %d subcarriers have 0 Peak Frequency Deviation", value.txName, zeros))
			}
		}
	}

	query = "Select Count(*) from SpecTxSubCarriers"
	rows, err = conn.Query(query)
	if err != nil {
		return single, false
	}
	items, ok = readSingleInt(rows)
	if !ok {
		return single, false
	}
	rows.Close()

	single.Items = items
	single.Errors = errors
	single.Warnings = warnings

	return single, true
}

func validateSpecRx(conn *sql.DB) (utils.SingleTableDetails, bool) {
	//Error Conditions:
	//1. Modulation PM - Mod Index Cannot be Zero
	//2. Modulation FM - Frequency Deviation FM Cannot be Zero
	var single utils.SingleTableDetails
	single.TableName = "SpecRx"
	query := "Select * from SpecRx"
	rows, err := conn.Query(query)
	if err != nil {
		return single, false
	}
	values, ok := readSpecRx(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	single.Items = len(values)
	single.Errors = 0
	single.Warnings = 0
	for _, value := range values {
		if strings.EqualFold(value.modulationScheme, "PM") {
			if value.tcModIndex.Float64 == 0 {
				single.Errors = single.Errors + 1
				single.ErrorList = append(single.ErrorList, fmt.Sprintf("Rx %s (PM): Mod Index cannot be 0", value.rxName))
			}
		} else if strings.EqualFold(value.modulationScheme, "FM") {
			if value.frequencyDeviationFM.Float64 == 0 {
				single.Errors = single.Errors + 1
				single.ErrorList = append(single.ErrorList, fmt.Sprintf("Rx %s (FM): Frequency Deviation cannot be 0", value.rxName))
			}
		}
	}
	return single, true
}

func validateSpecRxTMTC(conn *sql.DB) (utils.SingleTableDetails, bool) {
	//Error Conditions
	//1. Entry in SpecRx and not present in SpecRxTMTC
	var single utils.SingleTableDetails
	single.TableName = "SpecRxTMTC"
	query := "Select * from SpecRxTMTC"
	rows, err := conn.Query(query)
	if err != nil {
		return single, false
	}
	values, ok := readSpecRxTMTC(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	single.Items = len(values)
	query = "Select count(*) from SpecRx where RxName not in (Select RxName from SpecRxTMTC)"
	rows, err = conn.Query(query)
	if err != nil {
		return single, false
	}
	errs, ok := readSingleInt(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	single.Items = len(values)
	single.Errors = errs
	if errs > 0 {
		single.ErrorList = append(single.ErrorList, fmt.Sprintf("%d SpecRx entries have no TMTC entry", errs))
	}
	single.Warnings = 0

	return single, true
}

func validateSpecTp(conn *sql.DB) (utils.SingleTableDetails, bool) {
	var single utils.SingleTableDetails
	single.TableName = "SpecTp"
	query := "Select * from SpecTp"
	rows, err := conn.Query(query)
	if err != nil {
		return single, false
	}
	values, ok := readSpecTp(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	single.Items = len(values)
	single.Errors = 0
	single.Warnings = 0
	return single, true
}

func validateSpecTpRanging(conn *sql.DB) (utils.SingleTableDetails, bool) {
	var single utils.SingleTableDetails
	single.TableName = "SpecTpRanging"
	query := "Select count(*) from SpecTpRanging"
	rows, err := conn.Query(query)
	if err != nil {
		return single, false
	}
	num, ok := readSingleInt(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	single.Items = num
	single.Errors = 0
	single.Warnings = 0
	return single, true
}

func validateTestPhase(conn *sql.DB) (utils.SingleTableDetails, bool) {
	//Error Conditions:
	//1. One Phase to be selected
	var single utils.SingleTableDetails
	single.TableName = "TestPhases"
	query := "Select count(*) from TestPhases"
	rows, err := conn.Query(query)
	if err != nil {
		return single, false
	}
	values, ok := readSingleInt(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	single.Items = values
	single.Errors = 0
	single.Warnings = 0

	query = "Select count(*) from TestPhases where Selected = 1"
	rows, err = conn.Query(query)
	if err != nil {
		return single, false
	}
	sel, ok := readSingleInt(rows)
	if !ok {
		return single, false
	}
	if sel != 1 {
		single.Errors = single.Errors + 1
		single.ErrorList = append(single.ErrorList, fmt.Sprintf("Expected 1 selected Test Phase, found %d", sel))
	}
	rows.Close()
	return single, true
}

func validateUplinkLossTable(conn *sql.DB) (utils.SingleTableDetails, bool) {
	//Error Conditions:
	//1. Every Configuration to have a loss profile in selected test phase
	var single utils.SingleTableDetails
	single.TableName = "UplinkLoss"
	single.Items = 0
	single.Errors = 0
	single.Warnings = 0

	query := "Select Name from TestPhases where Selected = 1"
	rows, err := conn.Query(query)
	if err != nil {
		return single, false
	}
	temp1, ok := readSingleColumnString(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	var testPhase = temp1[0]

	query = "Select count(*) from Configurations where (ConfigType like 'Rx' or ConfigType like 'Tp') and "
	query = query + "ConfigName not in (Select ConfigName from UplinkLoss where TestPhaseName like ?)"
	rows, err = conn.Query(query, testPhase)
	if err != nil {
		return single, false
	}
	errs, ok := readSingleInt(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	single.Errors = single.Errors + errs
	if errs > 0 {
		single.ErrorList = append(single.ErrorList, fmt.Sprintf("%d configurations missing Uplink Loss profile", errs))
	}

	query = "Select count(*) from UplinkLoss"
	rows, err = conn.Query(query)
	if err != nil {
		return single, false
	}
	items, ok := readSingleInt(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	single.Items = items

	return single, true
}

func validateDownlinkLossTable(conn *sql.DB) (utils.SingleTableDetails, bool) {
	//Error Conditions:
	//1. Every Configuration to have a loss profile in selected test phase
	var single utils.SingleTableDetails
	single.TableName = "DownlinkLoss"
	single.Items = 0
	single.Errors = 0
	single.Warnings = 0

	query := "Select Name from TestPhases where Selected = 1"
	rows, err := conn.Query(query)
	if err != nil {
		return single, false
	}
	temp1, ok := readSingleColumnString(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	var testPhase = temp1[0]

	query = "Select count(*) from Configurations where (ConfigType like 'Tx' or ConfigType like 'Tp') and "
	query = query + "ConfigName not in (Select ConfigName from DownlinkLoss where TestPhaseName like ?)"
	rows, err = conn.Query(query, testPhase)
	if err != nil {
		return single, false
	}
	errs, ok := readSingleInt(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	single.Errors = single.Errors + errs
	if errs > 0 {
		single.ErrorList = append(single.ErrorList, fmt.Sprintf("%d configurations missing Downlink Loss profile", errs))
	}

	query = "Select count(*) from DownlinkLoss"
	rows, err = conn.Query(query)
	if err != nil {
		return single, false
	}
	items, ok := readSingleInt(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	single.Items = items

	return single, true
}

func validateDevices(conn *sql.DB) (utils.SingleTableDetails, bool) {

	var single utils.SingleTableDetails
	single.TableName = "Devices"
	single.Items = 0
	single.Errors = 0
	single.Warnings = 0

	query := "Select Count(*) from Devices"
	rows, err := conn.Query(query)
	if err != nil {
		return single, false
	}
	temp1, ok := readSingleInt(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	single.Items = temp1

	return single, true
}

func validateDeviceProfiles(conn *sql.DB) (utils.SingleTableDetails, bool) {

	var single utils.SingleTableDetails
	single.TableName = "DeviceProfile"
	single.Items = 0
	single.Errors = 0
	single.Warnings = 0

	query := "Select Count(*) from DeviceProfile"
	rows, err := conn.Query(query)
	if err != nil {
		return single, false
	}
	temp1, ok := readSingleInt(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	single.Items = temp1
	if temp1 == 0 {
		single.Errors = single.Errors + 1
		single.ErrorList = append(single.ErrorList, "Needs at least one profile")
	}
	return single, true
}

func validateDownlinkPowerProfile(conn *sql.DB) (utils.SingleTableDetails, bool) {
	//Error Conditions:
	//1. Atleast one channel power profile should be present.
	var single utils.SingleTableDetails
	single.TableName = "DownlinkPowerProfile"
	single.Items = 0
	single.Errors = 0
	single.Warnings = 0

	query := "Select Count(*) from DownlinkPowerProfile"
	rows, err := conn.Query(query)
	if err != nil {
		return single, false
	}
	temp1, ok := readSingleInt(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	single.Items = temp1
	if temp1 == 0 {
		single.Errors = single.Errors + 1
		single.ErrorList = append(single.ErrorList, "Needs at least one profile")
	}
	return single, true
}

func validateFrequencyProfile(conn *sql.DB) (utils.SingleTableDetails, bool) {
	var single utils.SingleTableDetails
	single.TableName = "FrequencyProfile"
	single.Items = 0
	single.Errors = 0
	single.Warnings = 0

	query := "Select Count(*) from FrequencyProfile"
	rows, err := conn.Query(query)
	if err != nil {
		return single, false
	}
	temp1, ok := readSingleInt(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	single.Items = temp1
	if temp1 == 0 {
		single.Errors = single.Errors + 1
		single.ErrorList = append(single.ErrorList, "Needs at least one profile")
	}
	return single, true
}

func validatePowerProfile(conn *sql.DB) (utils.SingleTableDetails, bool) {
	var single utils.SingleTableDetails
	single.TableName = "PowerProfile"
	single.Items = 0
	single.Errors = 0
	single.Warnings = 0

	query := "Select * from PowerProfile"
	rows, err := conn.Query(query)
	if err != nil {
		return single, false
	}
	values, ok := readPowerProfile(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	for _, value := range values {
		levels := strings.Split(value.powerLevels, ",")
		for _, level := range levels {
			_, err := strconv.ParseFloat(strings.TrimSpace(level), 64)
			if err != nil {
				single.Errors = single.Errors + 1
				single.ErrorList = append(single.ErrorList, fmt.Sprintf("Profile %s: Invalid power level '%s'", value.name, level))
				break
			}
		}
	}
	single.Items = len(values)
	return single, true
}

func validateSpectrumProfile(conn *sql.DB) (utils.SingleTableDetails, bool) {
	var single utils.SingleTableDetails
	single.TableName = "SpectrumProfile"
	single.Items = 0
	single.Errors = 0
	single.Warnings = 0

	query := "Select Count(*) from SpectrumProfile"
	rows, err := conn.Query(query)
	if err != nil {
		return single, false
	}
	temp1, ok := readSingleInt(rows)
	if !ok {
		return single, false
	}
	rows.Close()
	single.Items = temp1
	return single, true
}
