package communication

import (
	"database/sql"
	"fmt"
	"prismDB/utils"
	"strings"
	"time"

	_ "embed"

	_ "modernc.org/sqlite"
)

//go:embed prismdb-template.sql
var template string

func Create(auto utils.AutoPopulate) utils.Ack {
	db, err := sql.Open("sqlite", auto.DBPath)
	db.SetMaxOpenConns(1)
	if err != nil {
		return utils.Ack{
			OK:      false,
			Message: "Cannot Create database",
		}
	}
	defer db.Close()

	var tableName string
	err = db.QueryRow("SELECT name FROM sqlite_master WHERE type='table' AND name='Configurations';").Scan(&tableName)
	isNewDB := (err == sql.ErrNoRows) || (tableName == "")

	if isNewDB {
		ack := autoPopulateIndependentTables(db)
		if !ack.OK {
			return ack
		}
	}

	for _, name := range auto.DeletedRxNames {
		ack := DeleteBulk(db, "rx", name)
		if !ack.OK {
			return utils.Ack{OK: false, Message: "Unable to delete Rx: " + ack.Message}
		}
	}
	for _, name := range auto.DeletedTxNames {
		ack := DeleteBulk(db, "tx", name)
		if !ack.OK {
			return utils.Ack{OK: false, Message: "Unable to delete Tx: " + ack.Message}
		}
	}
	for _, name := range auto.DeletedTPNames {
		ack := DeleteBulk(db, "tp", name)
		if !ack.OK {
			return utils.Ack{OK: false, Message: "Unable to delete Tp: " + ack.Message}
		}
	}
	for _, name := range auto.DeletedPlNames {
		_, err := db.Exec("DELETE FROM SpecPL WHERE ConfigName = ?", name)
		if err != nil {
			return utils.Ack{OK: false, Message: "Unable to delete PL: " + err.Error()}
		}
	}
	for _, name := range auto.DeletedConfigNames {
		ack := DeleteBulk(db, "config", name)
		if !ack.OK {
			return utils.Ack{OK: false, Message: "Unable to delete Config: " + ack.Message}
		}
	}

	for i := range auto.RxNames {
		ack := autoPopulateRxRelated(db, auto.RxNames[i], auto.RxFrequencies[i], auto.RxModulation[i])
		if !ack.OK {
			return ack
		}
	}

	for i := range auto.TxNames {
		ack := autoPopulateTxRelated(db, auto.TxNames[i], auto.TxFrequencies[i], auto.TxPowers[i], auto.TxModulation[i])
		if !ack.OK {
			return ack
		}
	}

	for i := range auto.TPNames {
		ack := autoPopulateTPRelated(db, auto.TPNames[i], auto.TPRxNames[i], auto.TPTxNames[i])
		if !ack.OK {
			return ack
		}
	}

	for i := range auto.ConfigNames {
		var plName string
		var resMode string
		if i < len(auto.ConfigPlNames) {
			plName = auto.ConfigPlNames[i]
		}
		if i < len(auto.ConfigPlResolutionModes) {
			resMode = auto.ConfigPlResolutionModes[i]
		}
		ack := autoPopulateConfigurations(db, auto.ConfigNames[i], auto.ConfigTypes[i], auto.ConfigRxNames[i], auto.ConfigTxNames[i], auto.ConfigTPNames[i], plName, resMode, auto)
		if !ack.OK {
			return ack
		}
	}

	for i := range auto.PlNames {
		ack := autoPopulatePLRelated(db, auto.PlNames[i], auto.PlFrequencies[i], auto.PlPeakPowers[i], auto.PlAveragePowers[i])
		if !ack.OK {
			return ack
		}
	}

	//todo: Cable Calibration table to be added

	return utils.Ack{
		OK:      true,
		Message: "Database is Created",
	}

}

func autoPopulateIndependentTables(db *sql.DB) utils.Ack {
	tx, err := db.Begin()
	if err != nil {
		return utils.Ack{
			Message: "Unable to obtain Transaction Lock",
			OK:      false,
		}
	}
	_, err = tx.Exec(template)
	if err != nil {
		fmt.Println(err)
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert through sql file",
			OK:      false,
		}
	}

	//TestPhase with actual date and time
	now := time.Now()
	var testPhaseName string = "Pre-T&E"
	date := now.Format("02-01-2006")
	time := now.Format("15:04:05")
	var selected int = 1
	query := `INSERT OR REPLACE INTO TestPhases(Name, CreationDate, CreationTime, Selected)
	VALUES (?,?,?,?)`
	_, err = tx.Exec(query, testPhaseName, date, time, selected)
	if err != nil {
		fmt.Println(err)
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert in TestPhases Table",
			OK:      false,
		}
	}
	err = tx.Commit()
	if err != nil {
		fmt.Println("Commit failed in autoPopulateIndependentTables:", err)
		return utils.Ack{
			Message: "Unable to commit transaction for Independent Tables",
			OK:      false,
		}
	}
	return utils.Ack{
		Message: "",
		OK:      true,
	}
}

func autoPopulateRxRelated(db *sql.DB, rxName string, freq float64, modulation string) utils.Ack {
	tx, err := db.Begin()
	if err != nil {
		return utils.Ack{
			Message: "Unable to obtain Transaction Lock",
			OK:      false,
		}
	}
	//SpecRX
	values := getDefaultRxSpecs(modulation)
	var codeRate sql.NullFloat64
	if modulation == "CDMA" {
		codeRate.Valid = true
		codeRate.Float64 = 3069000
	}
	query := `INSERT OR REPLACE INTO SpecRx 
	(RxName, Frequency, MaxPower, TCSubCarrierFrequency, ModulationScheme, AcquisitionOffset, SweepRange, SweepRate, TCModIndex, FrequencyDeviationFM, CodeRateInMcps)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
	_, err = tx.Exec(query, rxName, freq, values[0], values[8], modulation, values[5], values[4], values[3], values[9], values[10], codeRate)
	if err != nil {
		fmt.Println(err)
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert in SpecRx Table",
			OK:      false,
		}
	}
	//SpecRxTMTC
	tmValues := getSampleRxTMTC(rxName)
	query = `INSERT OR REPLACE INTO SpecRxTMTC 
	(RxName, LockStatusMnemonic, LockStatusValue, BSLockStatusMnemonic, BSLockStatusValue, AGCMnemonic, LoopStressMnemonic, CommandCounterMnemonic, TestCommandSet, TestCommandReset)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
	_, err = tx.Exec(query, rxName, tmValues[0], tmValues[1], tmValues[2], tmValues[3], tmValues[4], tmValues[5], tmValues[6], tmValues[7], tmValues[8])
	if err != nil {
		fmt.Println(err)
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert in SpecRxTMTC Table",
			OK:      false,
		}
	}
	//SpectrumProfile for Rx
	spectrumValues := getSampleSpectrumSettings()
	query = `INSERT OR REPLACE INTO SpectrumProfile 
	(Name, CenterFrequency, Span, RBW, VBW)
	VALUES (?, ?, ?, ?, ?)`
	_, err = tx.Exec(query, rxName+"-Uplink", freq, spectrumValues[0], spectrumValues[1], spectrumValues[2])
	if err != nil {
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert in SpectrumSettings Table",
			OK:      false,
		}
	}
	// Frequency Profile for CDMA Doppler Test
	if modulation == "CDMA" {
		query := `INSERT OR REPLACE INTO FrequencyProfile(Name, MaxFrequency,StepSize,CommandingRequired,DopplerFile)VALUES (?,?,?,?,?)`
		_, err = tx.Exec(query, "Doppler-CDMA", 125000.0, 25000.0, "Yes", "/umacs/umacsops/sarc/resources/doppler.csv")
		if err != nil {
			fmt.Println(err)
			tx.Rollback()
			return utils.Ack{
				Message: "Unable to insert in FrequencyProfile Table",
				OK:      false,
			}
		}
	}

	// Test Specific Profile for receiver in PowerProfile Table
	if modulation == "FM" || modulation == "PSK" || modulation == "FSK" {
		query := `INSERT OR REPLACE INTO PowerProfile(Name, PowerLevels, NoOfCommandsAtThreshold, NoOfCommandsAtOtherLevels)VALUES (?,?,?,?)`
		_, err = tx.Exec(query, "CommandThreshold", "-75,-80,-90,-95,-100,-103,-104,-105", 20, 20)
		if err != nil {
			fmt.Println(err)
			tx.Rollback()
			return utils.Ack{
				Message: "Unable to insert in PowerProfile Table",
				OK:      false,
			}
		}
	} else if modulation == "PM" {
		query := `INSERT OR REPLACE INTO PowerProfile(Name, PowerLevels, NoOfCommandsAtThreshold, NoOfCommandsAtOtherLevels)VALUES (?,?,?,?)`
		_, err1 := tx.Exec(query, "CommandThreshold", "-75,-80,-90,-95,-100,-103,-104,-105", 20, 20)
		_, err2 := tx.Exec(query, "LockThreshold", "-75,-80,-90,-95,-100,-105,-110", 20, 20)
		if err1 != nil || err2 != nil {
			tx.Rollback()
			return utils.Ack{
				Message: "Unable to insert in PowerProfile Table",
				OK:      false,
			}
		}
	} else if modulation == "CDMA" {
		query := `INSERT OR REPLACE INTO PowerProfile(Name, PowerLevels, NoOfCommandsAtThreshold, NoOfCommandsAtOtherLevels)VALUES (?,?,?,?)`
		_, err = tx.Exec(query, "DopplerProfile", "-75,-80,-90,-95,-100,-105,-110", 20, 20)
		_, err2 := tx.Exec(query, "LockThreshold", "-75,-80,-90,-95,-100,-105,-110", 20, 20)
		if err != nil || err2 != nil {
			fmt.Println(err)
			tx.Rollback()
			return utils.Ack{
				Message: "Unable to insert in PowerProfile Table",
				OK:      false,
			}
		}
	}

	//TM Profile for receiver in TMProfile Table
	preReq, _ := getRxTM(rxName)
	query = `INSERT OR REPLACE INTO TMProfile(Name, PreRequisiteTM, LogTM)
	VALUES(?,?,?)`
	_, err = tx.Exec(query, rxName+"-TM", preReq, "")
	if err != nil {
		fmt.Println(err)
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert in TMProfile Table",
			OK:      false,
		}
	}

	//UpConverter Entries in UpDownConverter Table
	var upConverterNanme string = "UpConverter-" + rxName
	var IF float64 = 70e6
	var maxPowerCable int32 = -10
	var minPowerCable int32 = -90
	var maxPowerRadiated int32 = -50
	var minPowerRadiated int32 = -90
	query = `INSERT OR REPLACE INTO UpDownConverter(Name, InputFrequency, OutputFrequency, MaxPowerCable, MinPowerCable, MaxPowerRadiated, MinPowerRadiated)
	VALUES (?, ?, ?, ?, ?, ?, ?);`
	_, err = tx.Exec(query, upConverterNanme, IF, freq, maxPowerCable, minPowerCable, maxPowerRadiated, minPowerRadiated)
	if err != nil {
		fmt.Println(err)
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert UpConverter Details in UpDownConverter Table",
			OK:      false,
		}
	}

	err = tx.Commit()
	if err != nil {
		fmt.Println("Commit failed in autoPopulateRxRelated:", err)
		return utils.Ack{
			Message: "Unable to commit transaction for Rx Related",
			OK:      false,
		}
	}
	return utils.Ack{
		Message: "",
		OK:      true,
	}

}

func getRxTM(rxName string) (string, string) {
	lockMnenonic := rxName + "-Lock-Sts"
	tempMnemonic := rxName + "-Tmp"
	pre := "TM1:" + lockMnenonic + ",TM2:" + tempMnemonic
	post := pre
	return pre, post
}

func autoPopulateTxRelated(db *sql.DB, txName string, freq float64, power float64, modulation string) utils.Ack {
	var null sql.NullString
	null.Valid = false

	tx, err := db.Begin()
	if err != nil {
		return utils.Ack{
			Message: "Unable to obtain Transaction Lock",
			OK:      false,
		}
	}
	//SpecTx
	valuesFloat, _, isBurst, burstTime := getDefaultTxSpecs(modulation, freq)
	query := `INSERT OR REPLACE INTO SpecTx 
	(TxName, Frequency, Power, Spurious, Harmonics, AllowedFrequencyDeviation, AllowedPowerDevaition, ModulationScheme, IsBurst, BurstTime)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
	_, err = tx.Exec(query, txName, freq, power, valuesFloat[0], valuesFloat[1], valuesFloat[2], valuesFloat[3], modulation, isBurst, burstTime)
	if err != nil {
		fmt.Println(err)
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert in SpecTx Table",
			OK:      false,
		}
	}
	//SpecTxHarmonics

	query = `INSERT OR REPLACE INTO SpecTxHarmonics
	(TxName, HarmonicsID, HarmonicType, HarmonicsName, Frequency, TotalLossFromTxToSA)
	VALUES (?, ?, ?,?, ?, ?)`

	for i := 1; i < 3; i++ {
		var harmType string = "Harmonic"
		var harmFreq float64 = freq * 2
		var name string = "Second"
		if i == 2 {
			harmFreq = freq * 3
			name = "Third"
		}
		_, err = tx.Exec(query, txName, i, harmType, name, harmFreq, 0.0)
		if err != nil {
			fmt.Println(err)
			tx.Rollback()
			return utils.Ack{
				Message: "Unable to insert Harmonics in SpecTxHarmonics Table",
				OK:      false,
			}
		}
	}
	//SpecTxsubCarriers

	query = `INSERT OR REPLACE INTO SpecTxSubCarriers
	(TxName, SubCarrierID, SubCarrierName, Frequency, ModIndex, AllowedModIndexDeviation, AlwaysPresent, PeakFrequencyDeviation)
	VALUES (?,?,?,?,?,?,?,?)`

	if modulation == "PM" {
		for i := 1; i < 3; i++ {
			var subCarrID int = i
			var subCarrName string = "TM"
			var subCarrFreq float64 = 32000
			var subCarrMI float64 = 0.8
			var MIDev float64 = 0.0
			var alwaysPresent = "Yes"
			var peakFreqDev sql.NullFloat64
			peakFreqDev.Valid = false
			if i == 2 {
				subCarrName = "PB"
				alwaysPresent = "No"
				subCarrFreq = 128000
			}
			_, err = tx.Exec(query, txName, subCarrID, subCarrName, subCarrFreq, subCarrMI, MIDev, alwaysPresent, peakFreqDev)
			if err != nil {
				fmt.Println(err)
				tx.Rollback()
				return utils.Ack{
					Message: "Unable to insert  SubCarrier in SpexTxSubCarriers Table",
					OK:      false,
				}
			}
		}

	} else if modulation == "FSK" {

		_, err = tx.Exec(query, txName, 1, "FSK", 0, null, null, "Yes", 40000)
		if err != nil {
			fmt.Println(err)
			tx.Rollback()
			return utils.Ack{
				Message: "Unable to insert freq deviation for FSK in SpexTxSubCarriers Table",
				OK:      false,
			}
		}
	}
	//SpectrumProfile for Tx
	spectrumValues := getSampleSpectrumSettings()
	query = `INSERT OR REPLACE INTO SpectrumProfile 
	(Name, CenterFrequency, Span, RBW, VBW)
	VALUES (?, ?, ?, ?, ?)`
	_, err = tx.Exec(query, txName+"-Downlink", freq, spectrumValues[0], spectrumValues[1], spectrumValues[2])
	if err != nil {
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert in SpectrumProfile Table",
			OK:      false,
		}
	}
	spectrumValues[0] = 1e6
	_, err = tx.Exec(query, txName+"-In-Band", freq, spectrumValues[0], spectrumValues[1], spectrumValues[2])
	if err != nil {
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert Inband Spurious in SpectrumProfile Table",
			OK:      false,
		}
	}
	spectrumValues[0] = 100e6
	_, err = tx.Exec(query, txName+"-Out-Band", freq, spectrumValues[0], spectrumValues[1], spectrumValues[2])
	if err != nil {
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert OutOfBand Spurious in SpectrumProfile Table",
			OK:      false,
		}
	}
	//TM Profile for transmitter in TMProfile Table
	preReq, _ := getTxTM(txName)
	query = `INSERT OR REPLACE INTO TMProfile(Name, PreRequisiteTM, LogTM)
	VALUES(?,?,?)`
	_, err = tx.Exec(query, txName+"-TM", preReq, "")
	if err != nil {
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert Tx TM in TMProfile Table",
			OK:      false,
		}
	}

	query = `INSERT OR REPLACE INTO UpDownConverter(Name, InputFrequency, OutputFrequency, MaxPowerCable, MinPowerCable, MaxPowerRadiated, MinPowerRadiated)
	VALUES (?, ?, ?, ?, ?, ?, ?);`

	var downConverterNanme string = "DownConverter-" + txName
	var IF float64 = 70e6
	var maxPowerCable int32 = -20
	var minPowerCable int32 = -60
	var maxPowerRadiated int32 = -40
	var minPowerRadiated int32 = -90
	_, err = tx.Exec(query, downConverterNanme, freq, IF, maxPowerCable, minPowerCable, maxPowerRadiated, minPowerRadiated)
	if err != nil {
		fmt.Println(err)
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert DownConverter Details in UpDownConverter Table",
			OK:      false,
		}
	}
	err = tx.Commit()
	if err != nil {
		fmt.Println("Commit failed in autoPopulateTxRelated:", err)
		return utils.Ack{
			Message: "Unable to commit transaction for Tx Related",
			OK:      false,
		}
	}
	return utils.Ack{
		Message: "",
		OK:      true,
	}

}

func getTxTM(txName string) (string, string) {
	onMnenonic := txName + "-On-Sts"
	tempMnemonic := txName + "-Tmp"
	pre := "TM1:" + onMnenonic + ",TM2:" + tempMnemonic
	post := pre
	return pre, post
}

func autoPopulateTPRelated(db *sql.DB, tpName string, rxName string, txName string) utils.Ack {
	tx, err := db.Begin()
	if err != nil {
		return utils.Ack{
			Message: "Unable to obtain Transaction Lock",
			OK:      false,
		}
	}

	query := "Select Frequency from SpecRx where RxName = ?"
	rows, err := tx.Query(query, rxName)
	if err != nil {
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to read from SpecRx Table",
			OK:      false,
		}
	}
	freqs, ok := readSingleColumnFloat(rows)
	if !ok {
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to read from SpecRx Table",
			OK:      false,
		}
	}
	rows.Close()
	rxFreq := freqs[0]

	query = "Select Frequency from SpecTx where TxName = ?"
	rows, err = tx.Query(query, txName)
	if err != nil {
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to read from SpecTx Table",
			OK:      false,
		}
	}
	freqs, ok = readSingleColumnFloat(rows)
	if !ok {
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to read from SpecTx Table",
			OK:      false,
		}
	}
	rows.Close()
	txFreq := freqs[0]
	//SpecTp
	query = `INSERT OR REPLACE INTO SpecTp 
	(TpName, RxName, TxName)
	VALUES (?, ?, ?)`
	_, err = tx.Exec(query, tpName, rxName, txName)
	if err != nil {
		fmt.Println(err)
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert in SpecTransponder Table",
			OK:      false,
		}
	}
	//SpecTpRanging
	query = `INSERT OR REPLACE INTO SpecTpRanging 
	(TpName, RangingID, RangingName, ToneFrequency, UplinkToneMIOnlyRanging, UplinkToneMISimultaneousCmdAndRanging,
		TCMISimultaneousCmdAndRanging, DownlinkMI, AllowedDownlinkMIDeviation, AvailableForCommanding)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
	for i := 1; i < 3; i++ {
		var rngID int = i
		var rngName string = "500kHz-Tone"
		var rngFreq float64 = 500000
		var cmding string = "Yes"
		var toneMIRng float64 = 1.2
		var toneMICmdRng float64 = 1
		var tcMICmdRng float64 = 1
		var dlMI float64 = 1
		var dlMIDev float64 = 0
		if i == 2 {
			rngID = i + 1
			rngName = "100kHz-Tone"
			rngFreq = 100000

		}
		_, err = tx.Exec(query, tpName, rngID, rngName, rngFreq, toneMIRng, toneMICmdRng, tcMICmdRng, dlMI, dlMIDev, cmding)
		if err != nil {
			fmt.Println(err)
			tx.Rollback()
			return utils.Ack{
				Message: "Unable to insert tones in SpecTransponderRanging Table",
				OK:      false,
			}
		}
	}
	//SpectrumProfile for TP
	spectrumValues := getSampleSpectrumSettings()
	query = `INSERT OR REPLACE INTO SpectrumProfile 
	(Name, CenterFrequency, Span, RBW, VBW)
	VALUES (?, ?, ?, ?, ?)`
	_, err = tx.Exec(query, tpName+"-Uplink", rxFreq, spectrumValues[0], spectrumValues[1], spectrumValues[2])
	if err != nil {
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert in SpectrumSettings Table",
			OK:      false,
		}
	}

	query = `INSERT OR REPLACE INTO SpectrumProfile 
	(Name, CenterFrequency, Span, RBW, VBW)
	VALUES (?, ?, ?, ?, ?)`
	_, err = tx.Exec(query, tpName+"-Downlink", txFreq, spectrumValues[0], spectrumValues[1], spectrumValues[2])
	if err != nil {
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert in SpectrumSettings Table",
			OK:      false,
		}
	}
	//TM Profile for transponder in TMProfile Table
	preRx, _ := getRxTM(rxName)
	preTx, _ := getTxTM(txName)
	var preReq string = preRx + "," + preTx
	query = `INSERT OR REPLACE INTO TMProfile(Name, PreRequisiteTM, LogTM)
	VALUES(?,?,?)`
	_, err = tx.Exec(query, tpName+"-TM", preReq, "")
	if err != nil {
		fmt.Println(err)
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert in TMProfile Table",
			OK:      false,
		}
	}

	err = tx.Commit()
	if err != nil {
		fmt.Println("Commit failed in autoPopulateTPRelated:", err)
		return utils.Ack{
			Message: "Unable to commit transaction for Tp Related",
			OK:      false,
		}
	}
	return utils.Ack{
		Message: "",
		OK:      true,
	}
}

func autoPopulatePLRelated(db *sql.DB, configName string, freq float64, peakPower float64, avgPower float64) utils.Ack {
	tx, err := db.Begin()
	if err != nil {
		fmt.Println(err)
		return utils.Ack{
			OK:      false,
			Message: "Cannot Connect to Insert PL :" + err.Error(),
		}
	}

	// PulseProfile for payload
	pulseQuery := `INSERT OR REPLACE INTO PulseProfile(Name, TransientON, IQOn, AcquisitionTime, SweepTime, SweepCount,
		FilterType, FilterBandwidth, YTop, ThresholdLevel, Hysterisis, PPMTriggerLevel, PPMReferenceLevel, PPMYDivision, PPMChannel)
		VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`

	profiles := []string{"PPM-Profile", "VSA-Profile", "VSA-Profile-HR", configName + "-Pulse"}
	for _, pName := range profiles {
		_, err = tx.Exec(pulseQuery, pName, 0.5, 0, 100, 0.01, 10,
			"Gaussian", 1000000.0, -20.0, -40.0, 3.0, -30.0, -20.0, 10.0, "A")
		if err != nil {
			fmt.Println(err)
			tx.Rollback()
			return utils.Ack{
				OK:      false,
				Message: "Unable to insert in PulseProfile Table: " + err.Error(),
			}
		}
	}

	// TRMProfile for payload
	trmQuery := `INSERT OR REPLACE INTO TRMProfile(Name, NoOfTRMs, TimePerTRMInSecs, DelayBeforeFirstReadInSecs)
		VALUES (?,?,?,?)`
	_, err = tx.Exec(trmQuery, configName+"-TRM", 5, 10.0, 2.0)
	if err != nil {
		fmt.Println(err)
		tx.Rollback()
		return utils.Ack{
			OK:      false,
			Message: "Unable to insert in TRMProfile Table: " + err.Error(),
		}
	}

	err = tx.Commit()
	if err != nil {
		fmt.Println("Commit failed in autoPopulatePLRelated:", err)
		return utils.Ack{
			Message: "Unable to commit transaction for PL Related",
			OK:      false,
		}
	}

	return utils.Ack{
		OK:      true,
		Message: "Payload Successfully Populated",
	}
}

func autoPopulateConfigurations(db *sql.DB, configName string, configType string, rxName string, txName string, tpName string, plName string, resolutionMode string, auto utils.AutoPopulate) utils.Ack {
	tx, err := db.Begin()
	if err != nil {
		return utils.Ack{
			Message: "Unable to obtain Transaction Lock",
			OK:      false,
		}
	}

	// Delete existing tests and PL configurations to prevent duplicates on edit
	tx.Exec("DELETE FROM Tests WHERE ConfigName = ?", configName)
	tx.Exec("DELETE FROM SpecPL WHERE ConfigName = ?", configName)

	valuesString, valueInt := getDefaultConfigs(configType)
	query := `INSERT OR REPLACE INTO Configurations(ConfigName, ConfigType, RxName, TxName, TpName, PayloadName,
		TSMConfigurationName, CortexIFM, IntermediateFrequency, ProgrammableAttnUsed, DeviceProfileName)
	VALUES (?,?,?,?,?,?,?,?,?,?,?)`
	_, err = tx.Exec(query, configName, configType, rxName, txName, tpName, plName, valuesString[0], valuesString[2],
		valueInt, valuesString[4], "Default")
	if err != nil {
		fmt.Println(err)
		tx.Rollback()
		return utils.Ack{
			Message: "Unable to insert in Configurations Table",
			OK:      false,
		}
	}

	//Uplink Loss for receiver
	var testPhase string = "Pre-T&E"
	if strings.EqualFold(configType, "Rx") || strings.EqualFold(configType, "Tp") {
		var uplinkLoss string = "1,Common Loss,0.0,Common\n2,PM Loss,0,PM\n3,Spacecraft Loss,0.0,Spacecraft\n4,SA Loss,0.0,SA"
		query = `INSERT OR REPLACE INTO UplinkLoss(ConfigName, TestPhaseName, Profile)VALUES (?,?,?)`
		_, err = tx.Exec(query, configName, testPhase, uplinkLoss)
		if err != nil {
			fmt.Println(err)
			tx.Rollback()
			return utils.Ack{
				Message: "Unable to insert Uplink Loss for receiver",
				OK:      false,
			}
		}
	}

	//Downlink Loss for transmitter
	if strings.EqualFold(configType, "Tx") || strings.EqualFold(configType, "Tp") {
		var downlinkLoss string = "1,Common Loss,0.0,Common\n2,PM Loss,0.0,PM\n3,SA Loss,0.0,SA"
		query = `INSERT OR REPLACE INTO DownlinkLoss(ConfigName, TestPhaseName, Profile)VALUES (?,?,?)`
		_, err = tx.Exec(query, configName, testPhase, downlinkLoss)
		if err != nil {
			fmt.Println(err)
			tx.Rollback()
			return utils.Ack{
				Message: "Unable to insert Downlink Loss for transmitter",
				OK:      false,
			}
		}
	}

	// If ConfigType is PL, we need to populate SpecPL for this configuration
	if strings.EqualFold(configType, "PL") {
		var freq float64 = 2e9
		var peakPower float64 = 0
		var avgPower float64 = 0

		// Find payload values from the auto request
		for i, name := range auto.PlNames {
			if name == plName {
				freq = auto.PlFrequencies[i]
				peakPower = auto.PlPeakPowers[i]
				avgPower = auto.PlAveragePowers[i]
				break
			}
		}

		avgTxPower := peakPower - 6.0

		query := `INSERT OR REPLACE INTO SpecPL (
            ConfigName, ResolutionMode, OnTime, CenterFrequency, UplinkPower, 
            PeakPower, PeakPowerTolerance, AveragePower, AveragePowerTolerance, 
            DutyCycle, DutyCycleTolerance, PulsePeriod, PulsePeriodTolerance, 
            ReplicaPeriod, ReplicaPeriodTolerance, PulseWidth, PulseWidthTolerance, 
            PulseSeperation, PulseSeperationTolerance, RiseTime, RiseTimeTolerance, 
            FallTime, FallTimeTolerance, AverageTxPower, AverageTxPowerTolerance, 
            ChirpBandwidth, RepetitionRate,
			ChirpBandwidthTolerance, RepetitionRateTolerance, ReplicaRate, ReplicaRateTolerance,
			FrequencyShift, FrequencyShiftTolerance, Droop, DroopTolerance, Phase, PhaseTolerance,
			Overshoot, OvershootTolerance, ChirpRate, ChirpRateTolerance, ChirpRateDeviation,
			ChirpRateDeviationTolerance, Ripple, RippleTolerance
        ) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)`

		statement, err := tx.Prepare(query)
		if err != nil {
			tx.Rollback()
			return utils.Ack{OK: false, Message: "Error Preparing SpecPL: " + err.Error()}
		}
		_, err = statement.Exec(
			configName, ToNullString(resolutionMode), 1.0, freq, -20.0,
			peakPower, 0.5, avgPower, 0.5,
			25.0, 1.0, 3.6, 0.072,
			0.0, 0.0, 0.9, 0.018,
			2.7, 0.054, 0.001, 0.0,
			0.001, 0.0, avgTxPower, 0.5,
			400000.0, 250.0,
		)
		statement.Close()
		if err != nil {
			tx.Rollback()
			return utils.Ack{OK: false, Message: "Error Inserting SpecPL for Config: " + err.Error()}
		}
	}

	ack := populateTests(tx, configType, configName, rxName, txName, tpName)
	if !ack.OK {
		fmt.Println("populateTests failed:", ack.Message)
		tx.Rollback()
		return ack
	}

	err = tx.Commit()
	if err != nil {
		fmt.Println("Commit failed in autoPopulateConfigurations:", err)
		return utils.Ack{
			Message: "Unable to commit transaction for Configurations",
			OK:      false,
		}
	}
	return utils.Ack{
		Message: "",
		OK:      true,
	}
}

func populateTests(tx *sql.Tx, configType string, configName string, rxName string, txName string, tpName string) utils.Ack {
	if strings.EqualFold(configType, "Tp") {
		if tpName == "" {
			return utils.Ack{OK: false, Message: fmt.Sprintf("Configuration '%s' uses a transponder that is not listed", configName)}
		}
		return populateTpTestsForConfig(tx, configName, tpName)
	}
	if strings.EqualFold(configType, "Tx") {
		if txName == "" {
			return utils.Ack{OK: false, Message: fmt.Sprintf("Configuration '%s' uses a transmitter that is not listed", configName)}
		}
		return populateTxTestsForConfig(tx, configName, txName)
	}
	if strings.EqualFold(configType, "Rx") {
		if rxName == "" {
			return utils.Ack{OK: false, Message: fmt.Sprintf("Configuration '%s' uses a receiver that is not listed", configName)}
		}
		return populateRxTestsForConfig(tx, configName, rxName)
	}
	if strings.EqualFold(configType, "PL") {
		return populatePlTestsForConfig(tx, configName)
	}
	return utils.Ack{OK: true}
}

func populateRxTestsForConfig(tx *sql.Tx, configName string, rxName string) utils.Ack {
	query := "SELECT ModulationScheme from SpecRx where RxName = ?"
	rows, err := tx.Query(query, rxName)
	if err != nil {
		return utils.Ack{
			OK:      false,
			Message: "Cannot get Modulation from SpecRx Table",
		}
	}
	modulation, ok := readSingleString(rows)
	if !ok {
		return utils.Ack{
			OK:      false,
			Message: "Cannot get Modulation from SpecRx Table",
		}
	}
	rows.Close()
	var null sql.NullString
	null.Valid = true
	null.String = "Default"
	var normal sql.NullString
	normal.Valid = true
	normal.String = "Normal"
	var extreme sql.NullString
	extreme.Valid = true
	extreme.String = "Extreme"
	var verify sql.NullString
	verify.Valid = true
	verify.String = "Verify"
	var verifyDoppler sql.NullString
	verifyDoppler.Valid = true
	verifyDoppler.String = "VerifyDoppler"

	rxTestTypes := make([]string, 0)
	rxTestCategories := make([]sql.NullString, 0)
	if modulation == "PM" {
		rxTestTypes = append(rxTestTypes, "RFUplink", "CommandDynamic", "LockDynamic", "LoopStress", "LoopStress")
		rxTestCategories = append(rxTestCategories, null, verify, verify, normal, extreme)
	} else if modulation == "CDMA" {
		rxTestTypes = append(rxTestTypes, "RFUplink", "CommandDynamic", "LockDynamic", "CarrierAcquisition", "CarrierAcquisition")
		rxTestCategories = append(rxTestCategories, null, verifyDoppler, verify, normal, extreme)
	} else {
		rxTestTypes = append(rxTestTypes, "RFUplink", "CommandDynamic", "CarrierAcquisition", "CarrierAcquisition")
		rxTestCategories = append(rxTestCategories, null, verify, normal, extreme)
	}

	for i := range len(rxTestTypes) {
		values := getDefaultForRxTests(rxTestTypes[i], rxTestCategories[i], rxName)
		query := `INSERT OR REPLACE INTO Tests(ConfigName, TestType, TestCategory, ULProfileName,
					DLProfileName, PowerProfileName, FrequencyProfileName, DownlinkPowerProfileName,
					TMProfileName )
					VALUES (?,?,?,?,?,?,?,?,?)`
		_, err := tx.Exec(query, configName, rxTestTypes[i], rxTestCategories[i], values[0], values[1], values[2], values[4], values[3],
			values[6])
		if err != nil {
			fmt.Println(err)
			tx.Rollback()
			return utils.Ack{
				Message: "Unable to insert Rx Tests ",
				OK:      false,
			}
		}
	}
	return utils.Ack{
		Message: "",
		OK:      true,
	}

}

func populateTxTestsForConfig(tx *sql.Tx, configName string, txName string) utils.Ack {

	query := `SELECT ModulationScheme from SpecTx where TxName = ?`
	rows, err := tx.Query(query, txName)
	if err != nil {
		return utils.Ack{
			OK:      false,
			Message: "Cannot get Modulation from SpexTX Table",
		}
	}
	modulation, ok := readSingleString(rows)
	if !ok {
		return utils.Ack{
			OK:      false,
			Message: "Cannot get Modulation from SpexTX Table",
		}
	}
	rows.Close()
	var null sql.NullString
	null.Valid = true
	null.String = "Default"

	var power sql.NullString
	var harm sql.NullString
	var inband sql.NullString
	var outband sql.NullString

	power.Valid = true
	power.String = "Non-Coherent"
	harm.Valid = true
	harm.String = "Harmonics"
	inband.Valid = true
	inband.String = "In-Band"
	outband.Valid = true
	outband.String = "Out-Band"
	var subcarrTM sql.NullString
	subcarrTM.Valid = true
	subcarrTM.String = "TM"
	var subcarrPB sql.NullString
	subcarrPB.Valid = true
	subcarrPB.String = "PB"
	txTestTypes := make([]string, 0)
	txTestCategories := make([]sql.NullString, 0)
	if modulation == "PM" {
		txTestTypes = append(txTestTypes, "PowerMeasurement", "FrequencyMeasurement", "HarmonicsMeasurement", "SpuriousMeasurement", "SpuriousMeasurement", "ModIndexMeasurement", "ModIndexMeasurement")
		txTestCategories = append(txTestCategories, power, null, harm, inband, outband, subcarrTM, subcarrPB)
	} else if modulation == "PSK" {
		txTestTypes = append(txTestTypes, "PowerMeasurement", "FrequencyMeasurement", "HarmonicsMeasurement", "SpuriousMeasurement", "SpuriousMeasurement", "BandwidthMeasurement")
		txTestCategories = append(txTestCategories, power, null, harm, inband, outband, null)
	} else {
		txTestTypes = append(txTestTypes, "PowerMeasurement", "FrequencyMeasurement", "HarmonicsMeasurement", "SpuriousMeasurement", "SpuriousMeasurement")
		txTestCategories = append(txTestCategories, power, null, harm, inband, outband)
	}

	for i := range len(txTestTypes) {
		values := getDefaultForTxTests(txTestTypes[i], txTestCategories[i], txName)
		query := `INSERT OR REPLACE INTO Tests(ConfigName, TestType, TestCategory, ULProfileName,
						DLProfileName, PowerProfileName, FrequencyProfileName, DownlinkPowerProfileName,
						TMProfileName )
						VALUES (?,?,?,?,?,?,?,?,?)`
		_, err := tx.Exec(query, configName, txTestTypes[i], txTestCategories[i], values[0], values[1], values[2], values[4], values[3],
			values[6])
		if err != nil {
			fmt.Println(err)
			tx.Rollback()
			return utils.Ack{
				Message: "Unable to insert Tx Tests ",
				OK:      false,
			}
		}
	}

	return utils.Ack{
		Message: "",
		OK:      true,
	}
}
func populateTpTestsForConfig(tx *sql.Tx, configName string, tpName string) utils.Ack {
	var majorTone sql.NullString
	var minorTone sql.NullString
	var subCarr1 sql.NullString
	var subCarr2 sql.NullString
	majorTone.Valid = true
	majorTone.String = "500kHz-Tone"
	minorTone.Valid = true
	minorTone.String = "100kHz-Tone"
	subCarr1.Valid = true
	subCarr1.String = "TM"
	subCarr2.Valid = true
	subCarr2.String = "PB"

	tpTestTypes := make([]string, 0)
	tpTestCategories := make([]sql.NullString, 0)
	tpTestTypes = append(tpTestTypes, "Ranging", "Ranging", "SimultaneousCommandingAndRanging", "SimultaneousCommandingAndRanging", "ModIndexMeasurement", "ModIndexMeasurement", "ModIndexMeasurement", "ModIndexMeasurement")
	tpTestCategories = append(tpTestCategories, majorTone, minorTone, majorTone, minorTone, majorTone, minorTone, subCarr1, subCarr2)

	for i := range len(tpTestTypes) {
		values := getDefaultForTpTests(tpTestTypes[i], tpTestCategories[i], tpName)
		query := `INSERT OR REPLACE INTO Tests(ConfigName, TestType, TestCategory, ULProfileName,
						DLProfileName, PowerProfileName, FrequencyProfileName, DownlinkPowerProfileName,
						TMProfileName)
						VALUES (?,?,?,?,?,?,?,?,?)`
		_, err := tx.Exec(query, configName, tpTestTypes[i], tpTestCategories[i], values[0], values[1], values[2], values[4], values[3],
			values[6])
		if err != nil {
			fmt.Println(err)
			tx.Rollback()
			return utils.Ack{
				Message: "Unable to insert Tp Tests",
				OK:      false,
			}
		}
	}

	return utils.Ack{
		Message: "",
		OK:      true,
	}

}

func populatePlTestsForConfig(tx *sql.Tx, configName string) utils.Ack {
	var ppm sql.NullString
	ppm.Valid = true
	ppm.String = "PPM"
	var vsa sql.NullString
	vsa.Valid = true
	vsa.String = "VSA"

	plTestTypes := []string{"PulseMeasurement", "PulseAnalysis", "HighResolutionPulse"}
	plTestCategories := []sql.NullString{ppm, vsa, vsa}

	for i := range len(plTestTypes) {
		values := getDefaultForPlTests(plTestTypes[i], plTestCategories[i], configName)
		query := `INSERT OR REPLACE INTO Tests(ConfigName, TestType, TestCategory, ULProfileName,
						DLProfileName, PowerProfileName, FrequencyProfileName, DownlinkPowerProfileName,
						PulseProfileName )
						VALUES (?,?,?,?,?,?,?,?,?)`
		_, err := tx.Exec(query, configName, plTestTypes[i], plTestCategories[i], values[0], values[1], values[2], values[4], values[3],
			values[6])
		if err != nil {
			fmt.Println(err)
			tx.Rollback()
			return utils.Ack{
				Message: "Unable to insert Pl Tests ",
				OK:      false,
			}
		}
	}
	return utils.Ack{
		Message: "",
		OK:      true,
	}
}

func getDefaultForRxTests(testType string, testCategory sql.NullString, rxName string) []sql.NullString {
	var ulSpectrum sql.NullString
	var dlSpectrum sql.NullString
	var power sql.NullString
	var obwPower sql.NullString
	var loopStress sql.NullString
	var device sql.NullString
	var tm sql.NullString
	dlSpectrum.Valid = false
	obwPower.Valid = false

	device.Valid = true
	device.String = "Default"
	ulSpectrum.Valid = true
	ulSpectrum.String = rxName + "-Uplink"
	tm.Valid = true
	tm.String = rxName + "-TM"

	var values = make([]sql.NullString, 0)
	if strings.EqualFold(testType, "RFUplink") {
		power.Valid = true
		power.String = "RxNominal"
		loopStress.Valid = false
	}
	if strings.EqualFold(testType, "CommandDynamic") {
		power.Valid = true
		power.String = "CommandThreshold"
		loopStress.Valid = false
	}
	if strings.EqualFold(testCategory.String, "VerifyDoppler") {
		power.Valid = true
		power.String = "DopplerProfile"
		loopStress.Valid = true
		loopStress.String = "Doppler-CDMA"
	}
	if strings.EqualFold(testType, "LockDynamic") {
		power.Valid = true
		power.String = "LockThreshold"
		loopStress.Valid = false
	}
	if strings.EqualFold(testType, "LoopStress") {
		power.Valid = true
		power.String = "Frequency"
		loopStress.Valid = true
		if testCategory.String == "Extreme" {
			loopStress.String = "Frequency-Extreme"
		} else if testCategory.String == "Normal" {
			loopStress.String = "Frequency-Normal"
		}
	}
	if strings.EqualFold(testType, "CarrierAcquisition") {
		power.Valid = true
		power.String = "Frequency"
		loopStress.Valid = true
		if testCategory.String == "Extreme" {
			loopStress.String = "Frequency-Extreme"
		} else if testCategory.String == "Normal" {
			loopStress.String = "Frequency-Normal"
		}

	}

	values = append(values, ulSpectrum, dlSpectrum, power, obwPower, loopStress, device, tm)
	return values
}

func getDefaultForTxTests(testType string, testCategory sql.NullString, txName string) []sql.NullString {
	var ulSpectrum sql.NullString
	var dlSpectrum sql.NullString
	var power sql.NullString
	var obwPower sql.NullString
	var loopStress sql.NullString
	var device sql.NullString
	var tm sql.NullString
	ulSpectrum.Valid = false
	loopStress.Valid = false

	device.Valid = true
	device.String = "Default"
	dlSpectrum.Valid = true
	dlSpectrum.String = txName + "-Downlink"
	tm.Valid = true
	tm.String = txName + "-TM"

	var values = make([]sql.NullString, 0)
	if strings.EqualFold(testType, "PowerMeasurement") {
		obwPower.Valid = true
		obwPower.String = "TxProfile"
	}
	if strings.EqualFold(testType, "SpuriousMeasurement") {
		dlSpectrum.Valid = true
		dlSpectrum.String = txName + "-" + testCategory.String
	}

	values = append(values, ulSpectrum, dlSpectrum, power, obwPower, loopStress, device, tm)
	return values
}

func getDefaultForTpTests(testType string, _ sql.NullString, tpName string) []sql.NullString {
	var ulSpectrum sql.NullString
	var dlSpectrum sql.NullString
	var power sql.NullString
	var obwPower sql.NullString
	var loopStress sql.NullString
	var device sql.NullString
	var tm sql.NullString

	obwPower.Valid = false

	device.Valid = true
	device.String = "Default"
	ulSpectrum.Valid = true
	ulSpectrum.String = tpName + "-Uplink"
	dlSpectrum.Valid = true
	dlSpectrum.String = tpName + "-Downlink"
	tm.Valid = true
	tm.String = tpName + "-TM"
	if strings.EqualFold(testType, "Ranging") {
		power.Valid = true
		power.String = "Ranging"
	} else {
		power.Valid = true
		power.String = "RxNominal"
	}

	var values = make([]sql.NullString, 0)
	values = append(values, ulSpectrum, dlSpectrum, power, obwPower, loopStress, device, tm)
	return values
}

func getDefaultForPlTests(testType string, testCategory sql.NullString, configName string) []sql.NullString {
	var ulSpectrum sql.NullString
	var dlSpectrum sql.NullString
	var power sql.NullString
	var obwPower sql.NullString
	var loopStress sql.NullString
	var device sql.NullString
	var tm sql.NullString

	ulSpectrum.Valid = false
	power.Valid = false
	obwPower.Valid = false
	loopStress.Valid = false

	device.Valid = true
	device.String = "Default"

	dlSpectrum.Valid = true
	if testType == "HighResolutionPulse" {
		dlSpectrum.String = "Scat-Downlink-HR"
	} else {
		dlSpectrum.String = "Scat-Downlink"
	}

	tm.Valid = true
	if testCategory.String == "PPM" {
		if strings.HasSuffix(configName, "-A") {
			tm.String = "PPM-ProfileA"
		} else if strings.HasSuffix(configName, "-B") {
			tm.String = "PPM-ProfileB"
		} else {
			tm.String = "PPM-Profile"
		}
	} else if testCategory.String == "VSA" {
		if testType == "HighResolutionPulse" {
			tm.String = "VSA-Profile-HR"
		} else {
			tm.String = "VSA-Profile"
		}
	}

	var values = make([]sql.NullString, 0)
	values = append(values, ulSpectrum, dlSpectrum, power, obwPower, loopStress, device, tm)
	return values
}

func getDefaultRxSpecs(modulation string) []sql.NullFloat64 {
	var maxPower sql.NullFloat64
	var lock sql.NullFloat64
	var cmd sql.NullFloat64
	var sweepRate sql.NullFloat64
	var sweepRange sql.NullFloat64
	var carAcqOffset sql.NullFloat64
	var lsUpper sql.NullFloat64
	var lsLower sql.NullFloat64
	var tcSubcarr sql.NullFloat64
	var tcMI sql.NullFloat64
	var freqDev sql.NullFloat64
	maxPower.Float64 = -65
	maxPower.Valid = true
	cmd.Float64 = -105
	cmd.Valid = true
	lock.Float64 = -105
	lock.Valid = true
	tcSubcarr.Float64 = 8000
	tcSubcarr.Valid = true

	if modulation == "FM" {
		carAcqOffset.Float64 = 125000
		carAcqOffset.Valid = true
		freqDev.Float64 = 200000
		freqDev.Valid = true
	} else if modulation == "PM" {
		sweepRate.Float64 = 32000
		sweepRate.Valid = true
		sweepRange.Float64 = 125000
		sweepRange.Valid = true
		lsUpper.Float64 = 125000
		lsUpper.Valid = true
		lsLower.Float64 = -125000
		lsLower.Valid = true
		tcMI.Float64 = 1
		tcMI.Valid = true
	} else {
		carAcqOffset.Float64 = 125000
		carAcqOffset.Valid = true
	}
	var tbr = make([]sql.NullFloat64, 0)
	tbr = append(tbr, maxPower, lock, cmd, sweepRate, sweepRange, carAcqOffset, lsUpper, lsLower)
	tbr = append(tbr, tcSubcarr, tcMI, freqDev)
	return tbr
}

func getSampleRxTMTC(rxName string) []string {
	var mnemonics = make([]string, 0)
	mnemonics = append(mnemonics, rxName+"-LockStatus", "LOCK", rxName+"-BSLock", "LOCK", rxName+"-AGC", rxName+"-LoopStress", rxName+"-CC", "SET", "RESET")
	return mnemonics
}

func getSampleSpectrumSettings() []float64 {
	var specs = make([]float64, 0)
	var span float64 = 500000
	specs = append(specs, span, 10000, 3000)
	return specs
}

func getDefaultTxSpecs(modulation string, freq float64) ([]sql.NullFloat64, []sql.NullInt32, string, int32) {

	var spurious sql.NullFloat64
	var harmonics sql.NullFloat64
	var allowedFreqDev sql.NullFloat64
	var allowedPowerDev sql.NullFloat64
	var noOfSubCarr sql.NullInt32
	var noOfHarms sql.NullInt32
	var noOfSubHarmms sql.NullInt32
	var isBurst string
	var burstTime int32

	spurious.Float64 = -50
	spurious.Valid = true
	harmonics.Float64 = -30
	harmonics.Valid = true
	allowedFreqDev.Float64 = (freq * 2e-6)
	allowedFreqDev.Valid = true
	allowedPowerDev.Float64 = 0.5
	allowedPowerDev.Valid = true
	noOfSubCarr.Int32 = 0
	noOfSubCarr.Valid = true
	noOfHarms.Int32 = 2
	noOfHarms.Valid = true
	noOfSubHarmms.Int32 = 0
	noOfSubHarmms.Valid = true
	isBurst = "No"
	burstTime = 0

	if modulation == "PM" {
		noOfSubCarr.Int32 = 2

	} else if modulation == "FSK" {
		noOfSubCarr.Int32 = 1
	} else {
		noOfSubCarr.Int32 = 0
	}
	var tbr1 = make([]sql.NullFloat64, 0)
	tbr1 = append(tbr1, spurious, harmonics, allowedFreqDev, allowedPowerDev)
	var tbr2 = make([]sql.NullInt32, 0)
	tbr2 = append(tbr2, noOfSubCarr, noOfHarms, noOfSubHarmms)
	return tbr1, tbr2, isBurst, burstTime
}

func getDefaultConfigs(configType string) ([]sql.NullString, sql.NullInt32) {
	var tsmCfgName sql.NullString
	var linkedCfgs sql.NullString
	var cortexIFM sql.NullString
	var pmChannel sql.NullString
	var progAttnUsed sql.NullString
	var intFreq sql.NullInt32

	linkedCfgs.Valid = false
	if strings.EqualFold(configType, "Rx") {
		tsmCfgName.String = "Rx-Sample"
		tsmCfgName.Valid = true
		cortexIFM.String = "1"
		cortexIFM.Valid = true
		progAttnUsed.String = "Yes"
		progAttnUsed.Valid = true
		intFreq.Int32 = 70e6
		intFreq.Valid = true

	} else if strings.EqualFold(configType, "Tx") {
		tsmCfgName.String = "Tx-Sample"
		tsmCfgName.Valid = true
		pmChannel.String = "A"
		pmChannel.Valid = true
	} else if strings.EqualFold(configType, "PL") {
		tsmCfgName.String = "PL-Sample"
		tsmCfgName.Valid = true
		cortexIFM.Valid = false
		intFreq.Valid = false
		progAttnUsed.Valid = false
	} else {
		tsmCfgName.String = "Tp-Sample"
		tsmCfgName.Valid = true
		cortexIFM.String = "1"
		cortexIFM.Valid = true
		progAttnUsed.String = "Yes"
		progAttnUsed.Valid = true
		intFreq.Int32 = 70e6
		intFreq.Valid = true
		pmChannel.String = "A"
		pmChannel.Valid = true
	}

	var tbr = make([]sql.NullString, 0)
	tbr = append(tbr, tsmCfgName, linkedCfgs, cortexIFM, pmChannel, progAttnUsed)

	return tbr, intFreq
}
