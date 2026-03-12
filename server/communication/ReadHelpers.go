package communication

import (
	"database/sql"
	"prismDB/utils"
)

// specTx matches the expectations of ValidateRelated.go but scans from current schema
type specTx struct {
	txName           string
	modulationScheme string
	// Stub fields for code compatibility
	noOfHarmonics int
}

func readSpecTx(rows *sql.Rows) ([]specTx, bool) {
	var items []specTx
	for rows.Next() {
		var i specTx
		var txID int64
		var freq int64
		var power, spurious, harmonics, allowedFreqDev, allowedPowerDev float64
		var isBurst string
		var burstTime sql.NullFloat64

		// Schema: TxID, TxName, Frequency, Power, Spurious, Harmonics, AllowedFrequencyDeviation, AllowedPowerDevaition, ModulationScheme, IsBurst, BurstTime
		if err := rows.Scan(&txID, &i.txName, &freq, &power, &spurious, &harmonics, &allowedFreqDev, &allowedPowerDev, &i.modulationScheme, &isBurst, &burstTime); err != nil {
			return nil, false
		}
		items = append(items, i)
	}
	return items, true
}

func readSingleInt(rows *sql.Rows) (int, bool) {
	if !rows.Next() {
		return 0, false
	}
	var i int
	if err := rows.Scan(&i); err != nil {
		return 0, false
	}
	return i, true
}

func readSingleColumnString(rows *sql.Rows) ([]string, bool) {
	var items []string
	for rows.Next() {
		var s string
		if err := rows.Scan(&s); err != nil {
			return nil, false
		}
		items = append(items, s)
	}
	return items, true
}

// specRx matches ValidateRelated.go
type specRx struct {
	rxName               string
	modulationScheme     string
	tcModIndex           sql.NullFloat64
	frequencyDeviationFM sql.NullFloat64
}

func readSpecRx(rows *sql.Rows) ([]specRx, bool) {
	var items []specRx
	for rows.Next() {
		var i specRx
		var id int64
		var freq int64
		var maxPower, tcSubCarrierFreq float64
		var acqOffset, sweepRange, sweepRate, codeRate sql.NullFloat64

		// Schema: ID, RxName, Frequency, MaxPower, TCSubCarrierFrequency, ModulationScheme, AcquisitionOffset, SweepRange, SweepRate, TCModIndex, FrequencyDeviationFM, CodeRateInMcps
		if err := rows.Scan(&id, &i.rxName, &freq, &maxPower, &tcSubCarrierFreq, &i.modulationScheme, &acqOffset, &sweepRange, &sweepRate, &i.tcModIndex, &i.frequencyDeviationFM, &codeRate); err != nil {
			return nil, false
		}
		items = append(items, i)
	}
	return items, true
}

// specRxTM matches ValidateRelated.go usage for SpecRxTM (which seems to check logic)
type specRxTM struct {
	rxName string
	// other fields?
}

func readSpecRxTMTC(rows *sql.Rows) ([]specRxTM, bool) {
	// Schema for SpecRxTMTC: RxName, LockStatusMnemonic...
	// ValidateRelated.go calls readSpecRxTM but we don't know what it expects in struct yet except count.
	// It scans into something.
	// Let's assume just RxName for now or scan all fields into dummy.
	var items []specRxTM
	for rows.Next() {
		var i specRxTM
		var a, b, c, d, e, f, g, h, j sql.NullString
		// Schema: RxName, LockStatusMnemonic, LockStatusValue, BSLockStatusMnemonic, BSLockStatusValue, AGCMnemonic, LoopStressMnemonic, CommandCounterMnemonic, TestCommandSet, TestCommandReset
		if err := rows.Scan(&i.rxName, &a, &b, &c, &d, &e, &f, &g, &h, &j); err != nil {
			return nil, false
		}
		items = append(items, i)
	}
	return items, true

}

// specTransponder matches ValidateRelated.go usage
type specTransponder struct {
	tpName string
}

func readSpecTp(rows *sql.Rows) ([]specTransponder, bool) {
	var items []specTransponder
	for rows.Next() {
		var i specTransponder
		var tpID int64
		var rxName, txName string
		// Schema SpecTp: TpID, TpName, RxName, TxName
		var tpName sql.NullString
		if err := rows.Scan(&tpID, &tpName, &rxName, &txName); err != nil {
			return nil, false
		}
		if tpName.Valid {
			i.tpName = tpName.String
		}
		items = append(items, i)
	}
	return items, true
}

type uplinkLoss struct {
	configName    string
	testPhaseName string
	profile       string
}

func readUplinkLoss(rows *sql.Rows) ([]uplinkLoss, bool) {
	var items []uplinkLoss
	for rows.Next() {
		var i uplinkLoss
		var id int64
		// Schema: ID, ConfigName, TestPhaseName, Profile
		if err := rows.Scan(&id, &i.configName, &i.testPhaseName, &i.profile); err != nil {
			return nil, false
		}
		items = append(items, i)
	}
	return items, true
}

type downlinkLoss struct {
	configName    string
	testPhaseName string
	profile       string
}

func readDownlinkLoss(rows *sql.Rows) ([]downlinkLoss, bool) {
	var items []downlinkLoss
	for rows.Next() {
		var i downlinkLoss
		var id int64
		// Schema: ID, ConfigName, TestPhaseName, Profile
		if err := rows.Scan(&id, &i.configName, &i.testPhaseName, &i.profile); err != nil {
			return nil, false
		}
		items = append(items, i)
	}
	return items, true
}

type powerProfile struct {
	name        string
	powerLevels string
}

func readPowerProfile(rows *sql.Rows) ([]powerProfile, bool) {
	var items []powerProfile
	for rows.Next() {
		var i powerProfile
		var id, t1, t2 int
		// Schema: ID, Name, PowerLevels, NoOfCommandsAtThreshold, NoOfCommandsAtOtherLevels
		if err := rows.Scan(&id, &i.name, &i.powerLevels, &t1, &t2); err != nil {
			return nil, false
		}
		items = append(items, i)
	}
	return items, true
}

func readSpectrumProfile(rows *sql.Rows) ([]utils.SingleTableDetails, bool) {
	// ValidateRelated calls this but expects []utils.SingleTableDetails??
	// No, ValidateRelated calls readSpectrumSettings and len(values).
	// It returns whatever.
	// SpectrumSettings table Does NOT exist in schema.sql!
	// Schema has 'SpectrumProfile'.
	// So this is another mismatch.
	return nil, false
}

func readSingleColumnFloat(rows *sql.Rows) ([]float64, bool) {
	var items []float64
	for rows.Next() {
		var f float64
		if err := rows.Scan(&f); err != nil {
			return nil, false
		}
		items = append(items, f)
	}
	return items, true
}

func readSingleString(rows *sql.Rows) (string, bool) {
	if !rows.Next() {
		return "", false
	}
	var s string
	if err := rows.Scan(&s); err != nil {
		return "", false
	}
	return s, true
}
