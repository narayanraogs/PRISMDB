package communication

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"prismDB/database"
	"prismDB/utils"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
)

func updateRow(c *gin.Context) {
	var req utils.UpdateRequest
	var ack utils.Ack
	ack.OK = false

	if err := c.BindJSON(&req); err != nil {
		fmt.Printf("Error binding JSON: %v\n", err)
		ack.Message = "Bad Request"
		c.IndentedJSON(http.StatusOK, ack)
		return
	}

	conn, ok := clientMap[req.ID]
	if !ok {
		ack.Message = "Re-Register Database"
		c.IndentedJSON(http.StatusOK, ack)
		return
	}

	q := database.New(conn)
	ctx := context.Background()

	var err error
	switch strings.ToLower(req.TableName) {
	case "spectx":
		err = handleUpdateSpecTx(q, ctx, req)
	case "specrx":
		err = handleUpdateSpecRx(q, ctx, req)
	case "spectp", "spectransponder":
		err = handleUpdateSpecTp(q, ctx, req)
	case "tmprofile":
		err = handleUpdateTMProfile(q, ctx, req)
	case "updownconverter":
		err = handleUpdateUpDownConverter(q, ctx, req)
	case "testphases", "testphase":
		err = handleUpdateTestPhases(q, ctx, req)
	case "devices":
		err = handleUpdateDevices(q, ctx, req)
	case "spectxharmonics":
		err = handleUpdateSpecTxHarmonics(q, ctx, req)
	case "spectxsubcarriers":
		err = handleUpdateSpecTxSubCarriers(q, ctx, req)
	case "spectpranging", "spectransponderranging":
		err = handleUpdateSpecTpRanging(q, ctx, req)
	case "specrxtmtc", "specrxtm":
		err = handleUpdateSpecRxTMTC(q, ctx, req)
	case "configurations":
		err = handleUpdateConfigurations(q, ctx, req)
	case "tsmconfigurations":
		err = handleUpdateTSMConfigurations(q, ctx, req)
	case "frequencyprofile":
		err = handleUpdateFrequencyProfile(q, ctx, req)
	case "powerprofile":
		err = handleUpdatePowerProfile(q, ctx, req)
	case "spectrumprofile", "spectrumsettings":
		err = handleUpdateSpectrumProfile(q, ctx, req)
	case "pulseprofile":
		err = handleUpdatePulseProfile(q, ctx, req)
	case "trmprofile":
		err = handleUpdateTRMProfile(q, ctx, req)
	case "tests":
		err = handleUpdateTests(q, ctx, req)
	case "deviceprofile":
		err = handleUpdateDeviceProfile(q, ctx, req)
	case "downlinkpowerprofile", "obwpowerprofile", "obwpower":
		err = handleUpdateDownlinkPowerProfile(q, ctx, req)
	case "lossmeasurementfrequencies", "cablecalibrationfrequencies", "cablecalibration":
		err = handleUpdateLossMeasurementFrequencies(q, ctx, req)
	case "specpl":
		err = handleUpdateSpecPL(q, ctx, req)
	case "uplinkloss":
		err = handleUpdateUplinkLoss(q, ctx, req)
	case "downlinkloss":
		err = handleUpdateDownlinkLoss(q, ctx, req)
	default:
		// Fallback to a generic update if possible, or return error
		err = fmt.Errorf("update not implemented for table: %s", req.TableName)
	}

	if err != nil {
		fmt.Printf("Update Error: %v\n", err)
		ack.Message = err.Error()
	} else {
		ack.OK = true
		ack.Message = "Updated Successfully"
	}
	c.IndentedJSON(http.StatusOK, ack)
}

func addRow(c *gin.Context) {
	var req utils.UpdateRequest
	var ack utils.Ack
	ack.OK = false

	if err := c.BindJSON(&req); err != nil {
		ack.Message = "Bad Request"
		c.IndentedJSON(http.StatusOK, ack)
		return
	}

	conn, ok := clientMap[req.ID]
	if !ok {
		ack.Message = "Re-Register Database"
		c.IndentedJSON(http.StatusOK, ack)
		return
	}

	q := database.New(conn)
	ctx := context.Background()

	var err error
	switch strings.ToLower(req.TableName) {
	case "spectx":
		err = handleInsertSpecTx(q, ctx, req)
	case "specrx":
		err = handleInsertSpecRx(q, ctx, req)
	case "spectp", "spectransponder":
		err = handleInsertSpecTp(q, ctx, req)
	case "tmprofile":
		err = handleInsertTMProfile(q, ctx, req)
	case "updownconverter":
		err = handleInsertUpDownConverter(q, ctx, req)
	case "spectxharmonics":
		err = handleInsertSpecTxHarmonics(conn, q, ctx, req)
	case "spectxsubcarriers":
		err = handleInsertSpecTxSubCarriers(conn, q, ctx, req)
	case "spectpranging", "spectransponderranging":
		err = handleInsertSpecTpRanging(conn, q, ctx, req)
	case "specrxtmtc", "specrxtm":
		err = handleInsertSpecRxTMTC(q, ctx, req)
	case "configurations":
		err = handleInsertConfigurations(q, ctx, req)
	case "tsmconfigurations":
		err = handleInsertTSMConfigurations(q, ctx, req)
	case "frequencyprofile":
		err = handleInsertFrequencyProfile(q, ctx, req)
	case "powerprofile":
		err = handleInsertPowerProfile(q, ctx, req)
	case "spectrumprofile", "spectrumsettings":
		err = handleInsertSpectrumProfile(q, ctx, req)
	case "pulseprofile":
		err = handleInsertPulseProfile(q, ctx, req)
	case "trmprofile":
		err = handleInsertTRMProfile(q, ctx, req)
	case "tests":
		err = handleInsertTests(q, ctx, req)
	case "deviceprofile":
		err = handleInsertDeviceProfile(q, ctx, req)
	case "testphases", "testphase":
		err = handleInsertTestPhases(q, ctx, req)
	case "devices":
		err = handleInsertDevices(q, ctx, req)
	case "downlinkpowerprofile", "obwpowerprofile", "obwpower":
		err = handleInsertDownlinkPowerProfile(q, ctx, req)
	case "lossmeasurementfrequencies", "cablecalibrationfrequencies", "cablecalibration":
		err = handleInsertLossMeasurementFrequencies(q, ctx, req)
	case "specpl":
		err = handleInsertSpecPL(q, ctx, req)
	case "uplinkloss":
		err = handleInsertUplinkLoss(q, ctx, req)
	case "downlinkloss":
		err = handleInsertDownlinkLoss(q, ctx, req)
	default:
		err = fmt.Errorf("insert not implemented for table: %s", req.TableName)
	}

	if err != nil {
		ack.Message = err.Error()
	} else {
		ack.OK = true
		ack.Message = "Inserted Successfully"
	}
	c.IndentedJSON(http.StatusOK, ack)
}

func deleteRow(c *gin.Context) {
	var req utils.UpdateRequest
	var ack utils.Ack
	ack.OK = false

	if err := c.BindJSON(&req); err != nil {
		ack.Message = "Bad Request"
		c.IndentedJSON(http.StatusOK, ack)
		return
	}

	conn, ok := clientMap[req.ID]
	if !ok {
		ack.Message = "Re-Register Database"
		c.IndentedJSON(http.StatusOK, ack)
		return
	}

	// Use the DeleteRelated.go logic as requested
	ack = DeleteRow(conn, req.TableName, req.PrimaryKey)

	c.IndentedJSON(http.StatusOK, ack)
}

// Handler implementations...

func handleUpdateSpecTx(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	// Values: [TxID, TxName, Frequency, Power, Spurious, Harmonics, AllowedFrequencyDeviation, AllowedPowerDevaition, ModulationScheme, IsBurst, BurstTime]
	arg := database.UpdateSpecTxParams{
		TxName:                    req.Values[1],
		Frequency:                 parseInt(req.Values[2]),
		Power:                     parseFloat(req.Values[3]),
		Spurious:                  parseFloat(req.Values[4]),
		Harmonics:                 parseFloat(req.Values[5]),
		AllowedFrequencyDeviation: parseFloat(req.Values[6]),
		AllowedPowerDevaition:     parseFloat(req.Values[7]),
		ModulationScheme:          req.Values[8],
		IsBurst:                   req.Values[9],
		BurstTime:                 sql.NullFloat64{Float64: parseFloat(req.Values[10]), Valid: true},
		TxName_2:                  req.PrimaryKey,
	}
	return q.UpdateSpecTx(ctx, arg)
}

func handleInsertSpecTx(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertSpecTxParams{
		TxName:                    req.Values[1],
		Frequency:                 parseInt(req.Values[2]),
		Power:                     parseFloat(req.Values[3]),
		Spurious:                  parseFloat(req.Values[4]),
		Harmonics:                 parseFloat(req.Values[5]),
		AllowedFrequencyDeviation: parseFloat(req.Values[6]),
		AllowedPowerDevaition:     parseFloat(req.Values[7]),
		ModulationScheme:          req.Values[8],
		IsBurst:                   req.Values[9],
		BurstTime:                 sql.NullFloat64{Float64: parseFloat(req.Values[10]), Valid: true},
	}
	return q.InsertSpecTx(ctx, arg)
}

func handleUpdateSpecRx(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	// [ID, RxName, Frequency, MaxPower, TCSubCarrierFrequency, ModulationScheme, AcquisitionOffset, SweepRange, SweepRate, TCModIndex, FrequencyDeviationFM, CodeRateInMcps]
	arg := database.UpdateSpecRxParams{
		RxName:                req.Values[1],
		Frequency:             parseInt(req.Values[2]),
		MaxPower:              parseFloat(req.Values[3]),
		TCSubCarrierFrequency: parseFloat(req.Values[4]),
		ModulationScheme:      req.Values[5],
		AcquisitionOffset:     sql.NullFloat64{Float64: parseFloat(req.Values[6]), Valid: true},
		SweepRange:            sql.NullFloat64{Float64: parseFloat(req.Values[7]), Valid: true},
		SweepRate:             sql.NullFloat64{Float64: parseFloat(req.Values[8]), Valid: true},
		TCModIndex:            sql.NullFloat64{Float64: parseFloat(req.Values[9]), Valid: true},
		FrequencyDeviationFM:  sql.NullFloat64{Float64: parseFloat(req.Values[10]), Valid: true},
		CodeRateInMcps:        sql.NullFloat64{Float64: parseFloat(req.Values[11]), Valid: true},
		RxName_2:              req.PrimaryKey,
	}
	return q.UpdateSpecRx(ctx, arg)
}

func handleInsertSpecRx(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertSpecRxParams{
		RxName:                req.Values[1],
		Frequency:             parseInt(req.Values[2]),
		MaxPower:              parseFloat(req.Values[3]),
		TCSubCarrierFrequency: parseFloat(req.Values[4]),
		ModulationScheme:      req.Values[5],
		AcquisitionOffset:     sql.NullFloat64{Float64: parseFloat(req.Values[6]), Valid: true},
		SweepRange:            sql.NullFloat64{Float64: parseFloat(req.Values[7]), Valid: true},
		SweepRate:             sql.NullFloat64{Float64: parseFloat(req.Values[8]), Valid: true},
		TCModIndex:            sql.NullFloat64{Float64: parseFloat(req.Values[9]), Valid: true},
		FrequencyDeviationFM:  sql.NullFloat64{Float64: parseFloat(req.Values[10]), Valid: true},
		CodeRateInMcps:        sql.NullFloat64{Float64: parseFloat(req.Values[11]), Valid: true},
	}
	return q.InsertSpecRx(ctx, arg)
}

func handleUpdateTMProfile(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	// [ID, Name, PreRequisiteTM, LogTM]
	arg := database.UpdateTMProfileParams{
		Name:           req.Values[1],
		PreRequisiteTM: sql.NullString{String: req.Values[2], Valid: true},
		LogTM:          sql.NullString{String: req.Values[3], Valid: true},
		Name_2:         req.PrimaryKey,
	}
	return q.UpdateTMProfile(ctx, arg)
}

func handleInsertTMProfile(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertTMProfileParams{
		Name:           req.Values[1],
		PreRequisiteTM: sql.NullString{String: req.Values[2], Valid: true},
		LogTM:          sql.NullString{String: req.Values[3], Valid: true},
	}
	return q.InsertTMProfile(ctx, arg)
}

func handleUpdateUpDownConverter(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.UpdateUpDownConverterParams{
		Name:             req.Values[1],
		InputFrequency:   parseFloat(req.Values[2]),
		OutputFrequency:  parseFloat(req.Values[3]),
		MaxPowerCable:    parseFloat(req.Values[4]),
		MinPowerCable:    parseFloat(req.Values[5]),
		MaxPowerRadiated: sql.NullFloat64{Float64: parseFloat(req.Values[6]), Valid: true},
		MinPowerRadiated: sql.NullFloat64{Float64: parseFloat(req.Values[7]), Valid: true},
		Name_2:           req.PrimaryKey,
	}
	return q.UpdateUpDownConverter(ctx, arg)
}

func handleInsertUpDownConverter(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertUpDownConverterParams{
		Name:             req.Values[1],
		InputFrequency:   parseFloat(req.Values[2]),
		OutputFrequency:  parseFloat(req.Values[3]),
		MaxPowerCable:    parseFloat(req.Values[4]),
		MinPowerCable:    parseFloat(req.Values[5]),
		MaxPowerRadiated: sql.NullFloat64{Float64: parseFloat(req.Values[6]), Valid: true},
		MinPowerRadiated: sql.NullFloat64{Float64: parseFloat(req.Values[7]), Valid: true},
	}
	return q.InsertUpDownConverter(ctx, arg)
}

func handleUpdateTestPhases(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	selected := parseInt(req.Values[4])
	if selected == 1 {
		q.DeselectAllTestPhases(ctx)
	}
	arg := database.UpdateTestPhasesParams{
		Name:         req.Values[1],
		CreationDate: sql.NullString{String: req.Values[2], Valid: true},
		CreationTime: sql.NullString{String: req.Values[3], Valid: true},
		Selected:     selected,
		Name_2:       req.PrimaryKey,
	}
	return q.UpdateTestPhases(ctx, arg)
}

func handleUpdateDevices(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.UpdateDevicesParams{
		DeviceName:           req.Values[1],
		DeviceMake:           req.Values[2],
		DeviceType:           req.Values[3],
		IPAddress:            req.Values[4],
		ControlPort:          parseInt(req.Values[5]),
		AlternateControlPort: sql.NullInt64{Int64: parseInt(req.Values[6]), Valid: true},
		ReadPort:             sql.NullInt64{Int64: parseInt(req.Values[7]), Valid: true},
		DopplerPort:          sql.NullInt64{Int64: parseInt(req.Values[8]), Valid: true},
		TimeoutInMillisecs:   parseInt(req.Values[9]),
		DeviceName_2:         req.PrimaryKey,
	}
	return q.UpdateDevices(ctx, arg)
}

func handleInsertDevices(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertDevicesParams{
		DeviceName:           req.Values[1],
		DeviceMake:           req.Values[2],
		DeviceType:           req.Values[3],
		IPAddress:            req.Values[4],
		ControlPort:          parseInt(req.Values[5]),
		AlternateControlPort: sql.NullInt64{Int64: parseInt(req.Values[6]), Valid: true},
		ReadPort:             sql.NullInt64{Int64: parseInt(req.Values[7]), Valid: true},
		DopplerPort:          sql.NullInt64{Int64: parseInt(req.Values[8]), Valid: true},
		TimeoutInMillisecs:   parseInt(req.Values[9]),
	}
	return q.InsertDevices(ctx, arg)
}

func parseInt(s string) int64 {
	val, _ := strconv.ParseInt(s, 10, 64)
	return val
}

func parseFloat(s string) float64 {
	val, _ := strconv.ParseFloat(s, 64)
	return val
}

func NullToString(ns sql.NullString) string {
	if ns.Valid {
		return ns.String
	}
	return ""
}

func handleUpdateSpecTp(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.UpdateSpecTpParams{
		TpName:   sql.NullString{String: req.Values[1], Valid: true},
		RxName:   req.Values[2],
		TxName:   req.Values[3],
		TpName_2: sql.NullString{String: req.PrimaryKey, Valid: true},
	}
	return q.UpdateSpecTp(ctx, arg)
}

func handleInsertSpecTp(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertSpecTpParams{
		TpName: sql.NullString{String: req.Values[1], Valid: true},
		RxName: req.Values[2],
		TxName: req.Values[3],
	}
	return q.InsertSpecTp(ctx, arg)
}

// SpecTxHarmonics
func handleUpdateSpecTxHarmonics(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	keys := strings.Split(req.PrimaryKey, ":::")
	if len(keys) < 3 {
		return fmt.Errorf("invalid primary key for SpecTxHarmonics update")
	}

	existing, err := q.GetSpecTxHarmonicsByKey(ctx, database.GetSpecTxHarmonicsByKeyParams{
		TxName:        keys[0],
		HarmonicType:  keys[1],
		HarmonicsName: keys[2],
	})
	if err != nil {
		return fmt.Errorf("failed to fetch existing row for update: %w", err)
	}

	arg := database.UpdateSpecTxHarmonicsParams{
		TxName:              req.Values[0],
		HarmonicsID:         existing.HarmonicsID,
		HarmonicType:        req.Values[1],
		HarmonicsName:       req.Values[2],
		Frequency:           parseFloat(req.Values[3]),
		TotalLossFromTxToSA: parseFloat(req.Values[4]),
		TxName_2:            keys[0],
		HarmonicType_2:      keys[1],
		HarmonicsName_2:     keys[2],
	}
	return q.UpdateSpecTxHarmonics(ctx, arg)
}

func handleInsertSpecTxHarmonics(conn *sql.DB, q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	txName := req.Values[0]

	var maxID sql.NullInt64
	err := conn.QueryRowContext(ctx, `SELECT MAX("HarmonicsID") FROM "SpecTxHarmonics" WHERE "TxName" = ?`, txName).Scan(&maxID)
	if err != nil && err != sql.ErrNoRows {
		return fmt.Errorf("failed to get max ID: %w", err)
	}
	nextID := int64(1)
	if maxID.Valid {
		nextID = maxID.Int64 + 1
	}

	arg := database.InsertSpecTxHarmonicsParams{
		TxName:              txName,
		HarmonicsID:         nextID,
		HarmonicType:        req.Values[1],
		HarmonicsName:       req.Values[2],
		Frequency:           parseFloat(req.Values[3]),
		TotalLossFromTxToSA: parseFloat(req.Values[4]),
	}
	return q.InsertSpecTxHarmonics(ctx, arg)
}

func handleDeleteSpecTxHarmonics(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	keys := strings.Split(req.PrimaryKey, ":::")
	if len(keys) < 2 {
		return fmt.Errorf("invalid primary key for delete")
	}
	return q.DeleteSpecTxHarmonics(ctx, database.DeleteSpecTxHarmonicsParams{
		TxName:        keys[0],
		HarmonicType:  keys[1],
		HarmonicsName: keys[2],
	})
}

// SpecTxSubCarriers
func handleUpdateSpecTxSubCarriers(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	keys := strings.Split(req.PrimaryKey, ":::")
	if len(keys) < 2 {
		return fmt.Errorf("invalid primary key for SpecTxSubCarriers update")
	}

	existing, err := q.GetSpecTxSubCarrierByKey(ctx, database.GetSpecTxSubCarrierByKeyParams{
		TxName:         keys[0],
		SubCarrierName: keys[1],
	})
	if err != nil {
		return fmt.Errorf("failed to fetch existing row: %w", err)
	}

	arg := database.UpdateSpecTxSubCarriersParams{
		TxName:                   req.Values[0],
		SubCarrierID:             existing.SubCarrierID,
		SubCarrierName:           req.Values[1],
		Frequency:                parseFloat(req.Values[2]),
		ModIndex:                 sql.NullFloat64{Float64: parseFloat(req.Values[3]), Valid: true},
		AllowedModIndexDeviation: sql.NullFloat64{Float64: parseFloat(req.Values[4]), Valid: true},
		AlwaysPresent:            req.Values[5],
		PeakFrequencyDeviation:   sql.NullFloat64{Float64: parseFloat(req.Values[6]), Valid: true},
		TxName_2:                 keys[0],
		SubCarrierName_2:         keys[1],
	}
	return q.UpdateSpecTxSubCarriers(ctx, arg)
}

func handleInsertSpecTxSubCarriers(conn *sql.DB, q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	txName := req.Values[0]

	var maxID sql.NullInt64
	err := conn.QueryRowContext(ctx, `SELECT MAX("SubCarrierID") FROM "SpecTxSubCarriers" WHERE "TxName" = ?`, txName).Scan(&maxID)
	if err != nil && err != sql.ErrNoRows {
		return fmt.Errorf("failed to get max ID: %w", err)
	}
	nextID := int64(1)
	if maxID.Valid {
		nextID = maxID.Int64 + 1
	}

	arg := database.InsertSpecTxSubCarriersParams{
		TxName:                   txName,
		SubCarrierID:             nextID,
		SubCarrierName:           req.Values[1],
		Frequency:                parseFloat(req.Values[2]),
		ModIndex:                 sql.NullFloat64{Float64: parseFloat(req.Values[3]), Valid: true},
		AllowedModIndexDeviation: sql.NullFloat64{Float64: parseFloat(req.Values[4]), Valid: true},
		AlwaysPresent:            req.Values[5],
		PeakFrequencyDeviation:   sql.NullFloat64{Float64: parseFloat(req.Values[6]), Valid: true},
	}
	return q.InsertSpecTxSubCarriers(ctx, arg)
}

func handleDeleteSpecTxSubCarriers(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	keys := strings.Split(req.PrimaryKey, ":::")
	if len(keys) < 2 {
		return fmt.Errorf("invalid primary key for delete")
	}
	return q.DeleteSpecTxSubCarriers(ctx, database.DeleteSpecTxSubCarriersParams{
		TxName:         keys[0],
		SubCarrierName: keys[1],
	})
}

// SpecTpRanging
func handleUpdateSpecTpRanging(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	keys := strings.Split(req.PrimaryKey, ":::")
	if len(keys) < 2 {
		return fmt.Errorf("invalid primary key for SpecTpRanging update")
	}

	existing, err := q.GetSpecTpRangingByKey(ctx, database.GetSpecTpRangingByKeyParams{
		TpName:      keys[0],
		RangingName: keys[1],
	})
	if err != nil {
		return fmt.Errorf("failed to fetch existing row: %w", err)
	}

	arg := database.UpdateSpecTpRangingParams{
		TpName:                                req.Values[0],
		RangingID:                             existing.RangingID,
		RangingName:                           req.Values[1],
		ToneFrequency:                         parseFloat(req.Values[2]),
		UplinkToneMIOnlyRanging:               parseFloat(req.Values[3]),
		UplinkToneMISimultaneousCmdAndRanging: sql.NullFloat64{Float64: parseFloat(req.Values[4]), Valid: true},
		TCMISimultaneousCmdAndRanging:         parseFloat(req.Values[5]),
		DownlinkMI:                            parseFloat(req.Values[6]),
		AllowedDownlinkMIDeviation:            parseFloat(req.Values[7]),
		AvailableForCommanding:                req.Values[8],
		TpName_2:                              keys[0],
		RangingName_2:                         keys[1],
	}
	return q.UpdateSpecTpRanging(ctx, arg)
}

func handleInsertSpecTpRanging(conn *sql.DB, q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	tpName := req.Values[0]

	var maxID sql.NullInt64
	err := conn.QueryRowContext(ctx, `SELECT MAX("RangingID") FROM "SpecTpRanging" WHERE "TpName" = ?`, tpName).Scan(&maxID)
	if err != nil && err != sql.ErrNoRows {
		return fmt.Errorf("failed to get max ID: %w", err)
	}
	nextID := int64(1)
	if maxID.Valid {
		nextID = maxID.Int64 + 1
	}

	arg := database.InsertSpecTpRangingParams{
		TpName:                                tpName,
		RangingID:                             nextID,
		RangingName:                           req.Values[1],
		ToneFrequency:                         parseFloat(req.Values[2]),
		UplinkToneMIOnlyRanging:               parseFloat(req.Values[3]),
		UplinkToneMISimultaneousCmdAndRanging: sql.NullFloat64{Float64: parseFloat(req.Values[4]), Valid: true},
		TCMISimultaneousCmdAndRanging:         parseFloat(req.Values[5]),
		DownlinkMI:                            parseFloat(req.Values[6]),
		AllowedDownlinkMIDeviation:            parseFloat(req.Values[7]),
		AvailableForCommanding:                req.Values[8],
	}
	return q.InsertSpecTpRanging(ctx, arg)
}

func handleDeleteSpecTpRanging(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	keys := strings.Split(req.PrimaryKey, ":::")
	if len(keys) < 2 {
		return fmt.Errorf("invalid primary key for delete")
	}
	return q.DeleteSpecTpRanging(ctx, database.DeleteSpecTpRangingParams{
		TpName:      keys[0],
		RangingName: keys[1],
	})
}

func handleUpdateSpecRxTMTC(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	if len(req.Values) < 10 {
		return fmt.Errorf("expected 10 values for SpecRxTMTC, got %d", len(req.Values))
	}

	arg := database.UpdateSpecRxTMTCParams{
		RxName:                 req.Values[0],
		LockStatusMnemonic:     sql.NullString{String: req.Values[1], Valid: true},
		LockStatusValue:        sql.NullString{String: req.Values[2], Valid: true},
		BSLockStatusMnemonic:   req.Values[3],
		BSLockStatusValue:      req.Values[4],
		AGCMnemonic:            req.Values[5],
		CommandCounterMnemonic: req.Values[7],
		LoopStressMnemonic:     sql.NullString{String: req.Values[6], Valid: true},
		TestCommandSet:         req.Values[8],
		TestCommandReset:       req.Values[9],
		RxName_2:               req.PrimaryKey,
	}
	return q.UpdateSpecRxTMTC(ctx, arg)
}

func handleInsertSpecRxTMTC(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	if len(req.Values) < 10 {
		return fmt.Errorf("expected 10 values for SpecRxTMTC, got %d", len(req.Values))
	}

	arg := database.InsertSpecRxTMTCParams{
		RxName:                 req.Values[0],
		LockStatusMnemonic:     sql.NullString{String: req.Values[1], Valid: true},
		LockStatusValue:        sql.NullString{String: req.Values[2], Valid: true},
		BSLockStatusMnemonic:   req.Values[3],
		BSLockStatusValue:      req.Values[4],
		AGCMnemonic:            req.Values[5],
		CommandCounterMnemonic: req.Values[7],
		LoopStressMnemonic:     sql.NullString{String: req.Values[6], Valid: true},
		TestCommandSet:         req.Values[8],
		TestCommandReset:       req.Values[9],
	}
	return q.InsertSpecRxTMTC(ctx, arg)
}

func handleUpdateConfigurations(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	if len(req.Values) < 11 {
		return fmt.Errorf("expected 11 values for Configurations, got %d", len(req.Values))
	}
	arg := database.UpdateConfigurationsParams{
		ConfigName:            req.Values[0],
		ConfigType:            req.Values[1],
		RxName:                sql.NullString{String: req.Values[2], Valid: true},
		TxName:                sql.NullString{String: req.Values[3], Valid: true},
		TpName:                sql.NullString{String: req.Values[4], Valid: true},
		PayloadName:           sql.NullString{String: req.Values[8], Valid: true},
		TSMConfigurationName:  req.Values[5],
		CortexIFM:             sql.NullString{String: req.Values[6], Valid: true},
		IntermediateFrequency: sql.NullInt64{Int64: parseInt(req.Values[7]), Valid: true},
		ProgrammableAttnUsed:  sql.NullString{String: req.Values[10], Valid: true},
		DeviceProfileName:     req.Values[9],
		ConfigName_2:          req.PrimaryKey,
	}
	return q.UpdateConfigurations(ctx, arg)
}

func handleInsertConfigurations(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	if len(req.Values) < 11 {
		return fmt.Errorf("expected 11 values for Configurations, got %d", len(req.Values))
	}
	arg := database.InsertConfigurationsParams{
		ConfigName:            req.Values[0],
		ConfigType:            req.Values[1],
		RxName:                sql.NullString{String: req.Values[2], Valid: true},
		TxName:                sql.NullString{String: req.Values[3], Valid: true},
		TpName:                sql.NullString{String: req.Values[4], Valid: true},
		PayloadName:           sql.NullString{String: req.Values[8], Valid: true},
		TSMConfigurationName:  req.Values[5],
		CortexIFM:             sql.NullString{String: req.Values[6], Valid: true},
		IntermediateFrequency: sql.NullInt64{Int64: parseInt(req.Values[7]), Valid: true},
		ProgrammableAttnUsed:  sql.NullString{String: req.Values[10], Valid: true},
		DeviceProfileName:     req.Values[9],
	}
	return q.InsertConfigurations(ctx, arg)
}

func handleUpdateTSMConfigurations(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	if len(req.Values) < 10 {
		return fmt.Errorf("expected 10 values for TSMConfigurations, got %d", len(req.Values))
	}
	arg := database.UpdateTSMConfigurationParams{
		Name:            req.Values[0],
		UplinkToSC:      sql.NullString{String: req.Values[1], Valid: true},
		IncludePad:      sql.NullString{String: req.Values[2], Valid: true},
		ExcludePad:      sql.NullString{String: req.Values[3], Valid: true},
		UplinkToSA:      sql.NullString{String: req.Values[4], Valid: true},
		UplinkToPM:      sql.NullString{String: req.Values[5], Valid: true},
		TerminateUplink: sql.NullString{String: req.Values[6], Valid: true},
		DownlinkToSA:    sql.NullString{String: req.Values[7], Valid: true},
		DownlinkToPM:    sql.NullString{String: req.Values[8], Valid: true},
		AttnNumber:      sql.NullInt64{Int64: parseInt(req.Values[9]), Valid: true},
		Name_2:          req.PrimaryKey,
	}
	return q.UpdateTSMConfiguration(ctx, arg)
}

func handleInsertTSMConfigurations(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	if len(req.Values) < 10 {
		return fmt.Errorf("expected 10 values for TSMConfigurations, got %d", len(req.Values))
	}
	arg := database.InsertTSMConfigurationParams{
		Name:            req.Values[0],
		UplinkToSC:      sql.NullString{String: req.Values[1], Valid: true},
		IncludePad:      sql.NullString{String: req.Values[2], Valid: true},
		ExcludePad:      sql.NullString{String: req.Values[3], Valid: true},
		UplinkToSA:      sql.NullString{String: req.Values[4], Valid: true},
		UplinkToPM:      sql.NullString{String: req.Values[5], Valid: true},
		TerminateUplink: sql.NullString{String: req.Values[6], Valid: true},
		DownlinkToSA:    sql.NullString{String: req.Values[7], Valid: true},
		DownlinkToPM:    sql.NullString{String: req.Values[8], Valid: true},
		AttnNumber:      sql.NullInt64{Int64: parseInt(req.Values[9]), Valid: true},
	}
	return q.InsertTSMConfiguration(ctx, arg)
}

func handleUpdateFrequencyProfile(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.UpdateFrequencyProfileParams{
		Name:               req.Values[1],
		MaxFrequency:       sql.NullFloat64{Float64: parseFloat(req.Values[2]), Valid: true},
		StepSize:           sql.NullFloat64{Float64: parseFloat(req.Values[3]), Valid: true},
		CommandingRequired: req.Values[4],
		DopplerFile:        sql.NullString{String: req.Values[5], Valid: true},
		Name_2:             req.PrimaryKey,
	}
	return q.UpdateFrequencyProfile(ctx, arg)
}

func handleInsertFrequencyProfile(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertFrequencyProfileParams{
		Name:               req.Values[1],
		MaxFrequency:       sql.NullFloat64{Float64: parseFloat(req.Values[2]), Valid: true},
		StepSize:           sql.NullFloat64{Float64: parseFloat(req.Values[3]), Valid: true},
		CommandingRequired: req.Values[4],
		DopplerFile:        sql.NullString{String: req.Values[5], Valid: true},
	}
	return q.InsertFrequencyProfile(ctx, arg)
}

func handleUpdatePowerProfile(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.UpdatePowerProfileParams{
		Name:                      req.Values[1],
		PowerLevels:               req.Values[2],
		NoOfCommandsAtThreshold:   parseInt(req.Values[3]),
		NoOfCommandsAtOtherLevels: parseInt(req.Values[4]),
		Name_2:                    req.PrimaryKey,
	}
	return q.UpdatePowerProfile(ctx, arg)
}

func handleInsertPowerProfile(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertPowerProfileParams{
		Name:                      req.Values[1],
		PowerLevels:               req.Values[2],
		NoOfCommandsAtThreshold:   parseInt(req.Values[3]),
		NoOfCommandsAtOtherLevels: parseInt(req.Values[4]),
	}
	return q.InsertPowerProfile(ctx, arg)
}

func handleUpdateSpectrumProfile(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.UpdateSpectrumProfileParams{
		Name:            req.Values[1],
		CenterFrequency: parseFloat(req.Values[2]),
		Span:            parseFloat(req.Values[3]),
		RBW:             parseInt(req.Values[4]),
		VBW:             parseInt(req.Values[5]),
		Name_2:          req.PrimaryKey,
	}
	return q.UpdateSpectrumProfile(ctx, arg)
}

func handleInsertSpectrumProfile(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertSpectrumProfileParams{
		Name:            req.Values[1],
		CenterFrequency: parseFloat(req.Values[2]),
		Span:            parseFloat(req.Values[3]),
		RBW:             parseInt(req.Values[4]),
		VBW:             parseInt(req.Values[5]),
	}
	return q.InsertSpectrumProfile(ctx, arg)
}

func handleUpdatePulseProfile(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.UpdatePulseProfileParams{
		Name:              req.Values[1],
		TransientON:       parseFloat(req.Values[2]),
		IQOn:              parseInt(req.Values[3]),
		AcquisitionTime:   parseInt(req.Values[4]),
		SweepTime:         parseFloat(req.Values[5]),
		SweepCount:        parseInt(req.Values[6]),
		FilterType:        req.Values[7],
		FilterBandwidth:   parseFloat(req.Values[8]),
		YTop:              parseFloat(req.Values[9]),
		ThresholdLevel:    parseFloat(req.Values[10]),
		Hysterisis:        parseFloat(req.Values[11]),
		PPMTriggerLevel:   parseFloat(req.Values[12]),
		PPMReferenceLevel: parseFloat(req.Values[13]),
		PPMYDivision:      parseFloat(req.Values[14]),
		PPMChannel:        req.Values[15],
		Name_2:            req.PrimaryKey,
	}
	return q.UpdatePulseProfile(ctx, arg)
}

func handleInsertPulseProfile(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertPulseProfileParams{
		Name:              req.Values[1],
		TransientON:       parseFloat(req.Values[2]),
		IQOn:              parseInt(req.Values[3]),
		AcquisitionTime:   parseInt(req.Values[4]),
		SweepTime:         parseFloat(req.Values[5]),
		SweepCount:        parseInt(req.Values[6]),
		FilterType:        req.Values[7],
		FilterBandwidth:   parseFloat(req.Values[8]),
		YTop:              parseFloat(req.Values[9]),
		ThresholdLevel:    parseFloat(req.Values[10]),
		Hysterisis:        parseFloat(req.Values[11]),
		PPMTriggerLevel:   parseFloat(req.Values[12]),
		PPMReferenceLevel: parseFloat(req.Values[13]),
		PPMYDivision:      parseFloat(req.Values[14]),
		PPMChannel:        req.Values[15],
	}
	return q.InsertPulseProfile(ctx, arg)
}

func handleUpdateTRMProfile(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.UpdateTRMProfileParams{
		Name:                       sql.NullString{String: req.Values[0], Valid: true},
		NoOfTRMs:                   parseInt(req.Values[1]),
		TimePerTRMInSecs:           parseFloat(req.Values[2]),
		DelayBeforeFirstReadInSecs: parseFloat(req.Values[3]),
		Name_2:                     sql.NullString{String: req.PrimaryKey, Valid: true},
	}
	return q.UpdateTRMProfile(ctx, arg)
}

func handleInsertTRMProfile(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertTRMProfileParams{
		Name:                       sql.NullString{String: req.Values[0], Valid: true},
		NoOfTRMs:                   parseInt(req.Values[1]),
		TimePerTRMInSecs:           parseFloat(req.Values[2]),
		DelayBeforeFirstReadInSecs: parseFloat(req.Values[3]),
	}
	return q.InsertTRMProfile(ctx, arg)
}

func handleUpdateTests(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.UpdateTestsParams{
		ConfigName:               req.Values[0],
		TestType:                 req.Values[1],
		TestCategory:             req.Values[2],
		ULProfileName:            sql.NullString{String: req.Values[3], Valid: true},
		DLProfileName:            sql.NullString{String: req.Values[4], Valid: true},
		PowerProfileName:         sql.NullString{String: req.Values[5], Valid: true},
		FrequencyProfileName:     sql.NullString{String: req.Values[6], Valid: true},
		DownlinkPowerProfileName: sql.NullString{String: req.Values[7], Valid: true},
		PulseProfileName:         sql.NullString{String: req.Values[8], Valid: true},
		TRMProfileName:           sql.NullString{String: req.Values[9], Valid: true},
		TMProfileName:            sql.NullString{String: req.Values[10], Valid: true},
		ID:                       parseInt(req.PrimaryKey),
	}
	return q.UpdateTests(ctx, arg)
}

func handleInsertTests(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertTestsParams{
		ConfigName:               req.Values[0],
		TestType:                 req.Values[1],
		TestCategory:             req.Values[2],
		ULProfileName:            sql.NullString{String: req.Values[3], Valid: true},
		DLProfileName:            sql.NullString{String: req.Values[4], Valid: true},
		PowerProfileName:         sql.NullString{String: req.Values[5], Valid: true},
		FrequencyProfileName:     sql.NullString{String: req.Values[6], Valid: true},
		DownlinkPowerProfileName: sql.NullString{String: req.Values[7], Valid: true},
		PulseProfileName:         sql.NullString{String: req.Values[8], Valid: true},
		TRMProfileName:           sql.NullString{String: req.Values[9], Valid: true},
		TMProfileName:            sql.NullString{String: req.Values[10], Valid: true},
	}
	return q.InsertTests(ctx, arg)
}

func handleUpdateDeviceProfile(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.UpdateDeviceProfileParams{
		DeviceProfileName:   req.Values[0],
		SAName:              sql.NullString{String: req.Values[1], Valid: true},
		VSAName:             sql.NullString{String: req.Values[2], Valid: true},
		PMName:              sql.NullString{String: req.Values[3], Valid: true},
		PPMName:             sql.NullString{String: req.Values[4], Valid: true},
		TSMName:             sql.NullString{String: req.Values[5], Valid: true},
		GTxName:             sql.NullString{String: req.Values[6], Valid: true},
		SGName:              sql.NullString{String: req.Values[7], Valid: true},
		VSGName:             sql.NullString{String: req.Values[8], Valid: true},
		DeviceProfileName_2: req.PrimaryKey,
	}
	return q.UpdateDeviceProfile(ctx, arg)
}

func handleInsertDeviceProfile(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertDeviceProfileParams{
		DeviceProfileName: req.Values[0],
		SAName:            sql.NullString{String: req.Values[1], Valid: true},
		VSAName:           sql.NullString{String: req.Values[2], Valid: true},
		PMName:            sql.NullString{String: req.Values[3], Valid: true},
		PPMName:           sql.NullString{String: req.Values[4], Valid: true},
		TSMName:           sql.NullString{String: req.Values[5], Valid: true},
		GTxName:           sql.NullString{String: req.Values[6], Valid: true},
		SGName:            sql.NullString{String: req.Values[7], Valid: true},
		VSGName:           sql.NullString{String: req.Values[8], Valid: true},
	}
	return q.InsertDeviceProfile(ctx, arg)
}

func handleInsertTestPhases(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	q.DeselectAllTestPhases(ctx)
	arg := database.InsertTestPhasesParams{
		Name:         req.Values[0],
		CreationDate: sql.NullString{String: req.Values[1], Valid: true},
		CreationTime: sql.NullString{String: req.Values[2], Valid: true},
		Selected:     1,
	}
	return q.InsertTestPhases(ctx, arg)
}

func handleUpdateDownlinkPowerProfile(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.UpdateDownlinkPowerProfileParams{
		Name:       sql.NullString{String: req.Values[1], Valid: true},
		PMChannel:  req.Values[2],
		OccupiedBW: parseInt(req.Values[3]),
		Name_2:     sql.NullString{String: req.PrimaryKey, Valid: true},
	}
	return q.UpdateDownlinkPowerProfile(ctx, arg)
}

func handleInsertDownlinkPowerProfile(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertDownlinkPowerProfileParams{
		Name:       sql.NullString{String: req.Values[1], Valid: true},
		PMChannel:  req.Values[2],
		OccupiedBW: parseInt(req.Values[3]),
	}
	return q.InsertDownlinkPowerProfile(ctx, arg)
}

func handleUpdateLossMeasurementFrequencies(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.UpdateLossMeasurementFrequenciesParams{
		Description:   req.Values[1],
		Frequency:     parseFloat(req.Values[2]),
		Description_2: req.PrimaryKey,
	}
	return q.UpdateLossMeasurementFrequencies(ctx, arg)
}

func handleInsertLossMeasurementFrequencies(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertLossMeasurementFrequenciesParams{
		Description: req.Values[1],
		Frequency:   parseFloat(req.Values[2]),
	}
	return q.InsertLossMeasurementFrequencies(ctx, arg)
}

func handleUpdateSpecPL(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	keys := strings.Split(req.PrimaryKey, ":::")
	if len(keys) < 2 {
		return fmt.Errorf("invalid primary key for SpecPL update: expected ConfigName:::ResolutionMode")
	}

	arg := database.UpdateSpecPLParams{
		ConfigName:                  req.Values[0],
		ResolutionMode:              ToNullString(req.Values[1]),
		OnTime:                      parseFloat(req.Values[2]),
		CenterFrequency:             parseFloat(req.Values[3]),
		UplinkPower:                 parseFloat(req.Values[4]),
		PeakPower:                   NullToFloat(req.Values[5]),
		PeakPowerTolerance:          NullToFloat(req.Values[6]),
		AveragePower:                NullToFloat(req.Values[7]),
		AveragePowerTolerance:       NullToFloat(req.Values[8]),
		DutyCycle:                   NullToFloat(req.Values[9]),
		DutyCycleTolerance:          NullToFloat(req.Values[10]),
		PulsePeriod:                 parseFloat(req.Values[11]),
		PulsePeriodTolerance:        NullToFloat(req.Values[12]),
		ReplicaPeriod:               NullToFloat(req.Values[13]),
		ReplicaPeriodTolerance:      NullToFloat(req.Values[14]),
		PulseWidth:                  parseFloat(req.Values[15]),
		PulseWidthTolerance:         NullToFloat(req.Values[16]),
		PulseSeperation:             NullToFloat(req.Values[17]),
		PulseSeperationTolerance:    NullToFloat(req.Values[18]),
		RiseTime:                    NullToFloat(req.Values[19]),
		RiseTimeTolerance:           NullToFloat(req.Values[20]),
		FallTime:                    NullToFloat(req.Values[21]),
		FallTimeTolerance:           NullToFloat(req.Values[22]),
		AverageTxPower:              NullToFloat(req.Values[23]),
		AverageTxPowerTolerance:     NullToFloat(req.Values[24]),
		ChirpBandwidth:              NullToFloat(req.Values[25]),
		ChirpBandwidthTolerance:     NullToFloat(req.Values[26]),
		RepetitionRate:              NullToFloat(req.Values[27]),
		RepetitionRateTolerance:     NullToFloat(req.Values[28]),
		ReplicaRate:                 NullToFloat(req.Values[29]),
		ReplicaRateTolerance:        NullToFloat(req.Values[30]),
		FrequencyShift:              NullToFloat(req.Values[31]),
		FrequencyShiftTolerance:     NullToFloat(req.Values[32]),
		Droop:                       NullToFloat(req.Values[33]),
		DroopTolerance:              NullToFloat(req.Values[34]),
		Phase:                       NullToFloat(req.Values[35]),
		PhaseTolerance:              NullToFloat(req.Values[36]),
		Overshoot:                   NullToFloat(req.Values[37]),
		OvershootTolerance:          NullToFloat(req.Values[38]),
		ChirpRate:                   NullToFloat(req.Values[39]),
		ChirpRateTolerance:          NullToFloat(req.Values[40]),
		ChirpRateDeviation:          NullToFloat(req.Values[41]),
		ChirpRateDeviationTolerance: NullToFloat(req.Values[42]),
		Ripple:                      NullToFloat(req.Values[43]),
		RippleTolerance:             NullToFloat(req.Values[44]),
		ConfigName_2:                keys[0],
		ResolutionMode_2:            ToNullString(keys[1]),
	}
	return q.UpdateSpecPL(ctx, arg)
}

func handleInsertSpecPL(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertSpecPLParams{
		ConfigName:                  req.Values[0],
		ResolutionMode:              ToNullString(req.Values[1]),
		OnTime:                      parseFloat(req.Values[2]),
		CenterFrequency:             parseFloat(req.Values[3]),
		UplinkPower:                 parseFloat(req.Values[4]),
		PeakPower:                   NullToFloat(req.Values[5]),
		PeakPowerTolerance:          NullToFloat(req.Values[6]),
		AveragePower:                NullToFloat(req.Values[7]),
		AveragePowerTolerance:       NullToFloat(req.Values[8]),
		DutyCycle:                   NullToFloat(req.Values[9]),
		DutyCycleTolerance:          NullToFloat(req.Values[10]),
		PulsePeriod:                 parseFloat(req.Values[11]),
		PulsePeriodTolerance:        NullToFloat(req.Values[12]),
		ReplicaPeriod:               NullToFloat(req.Values[13]),
		ReplicaPeriodTolerance:      NullToFloat(req.Values[14]),
		PulseWidth:                  parseFloat(req.Values[15]),
		PulseWidthTolerance:         NullToFloat(req.Values[16]),
		PulseSeperation:             NullToFloat(req.Values[17]),
		PulseSeperationTolerance:    NullToFloat(req.Values[18]),
		RiseTime:                    NullToFloat(req.Values[19]),
		RiseTimeTolerance:           NullToFloat(req.Values[20]),
		FallTime:                    NullToFloat(req.Values[21]),
		FallTimeTolerance:           NullToFloat(req.Values[22]),
		AverageTxPower:              NullToFloat(req.Values[23]),
		AverageTxPowerTolerance:     NullToFloat(req.Values[24]),
		ChirpBandwidth:              NullToFloat(req.Values[25]),
		ChirpBandwidthTolerance:     NullToFloat(req.Values[26]),
		RepetitionRate:              NullToFloat(req.Values[27]),
		RepetitionRateTolerance:     NullToFloat(req.Values[28]),
		ReplicaRate:                 NullToFloat(req.Values[29]),
		ReplicaRateTolerance:        NullToFloat(req.Values[30]),
		FrequencyShift:              NullToFloat(req.Values[31]),
		FrequencyShiftTolerance:     NullToFloat(req.Values[32]),
		Droop:                       NullToFloat(req.Values[33]),
		DroopTolerance:              NullToFloat(req.Values[34]),
		Phase:                       NullToFloat(req.Values[35]),
		PhaseTolerance:              NullToFloat(req.Values[36]),
		Overshoot:                   NullToFloat(req.Values[37]),
		OvershootTolerance:          NullToFloat(req.Values[38]),
		ChirpRate:                   NullToFloat(req.Values[39]),
		ChirpRateTolerance:          NullToFloat(req.Values[40]),
		ChirpRateDeviation:          NullToFloat(req.Values[41]),
		ChirpRateDeviationTolerance: NullToFloat(req.Values[42]),
		Ripple:                      NullToFloat(req.Values[43]),
		RippleTolerance:             NullToFloat(req.Values[44]),
	}
	return q.InsertSpecPL(ctx, arg)
}

func handleUpdateUplinkLoss(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	parts := strings.Split(req.PrimaryKey, ":::")
	if len(parts) != 2 {
		return fmt.Errorf("invalid primary key for UplinkLoss: %s", req.PrimaryKey)
	}
	arg := database.UpdateUplinkLossParams{
		ConfigName:      req.Values[0],
		TestPhaseName:   req.Values[1],
		Profile:         req.Values[2],
		ConfigName_2:    parts[0],
		TestPhaseName_2: parts[1],
	}
	return q.UpdateUplinkLoss(ctx, arg)
}

func handleInsertUplinkLoss(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertUplinkLossParams{
		ConfigName:    req.Values[0],
		TestPhaseName: req.Values[1],
		Profile:       req.Values[2],
	}
	return q.InsertUplinkLoss(ctx, arg)
}

func handleUpdateDownlinkLoss(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	parts := strings.Split(req.PrimaryKey, ":::")
	if len(parts) != 2 {
		return fmt.Errorf("invalid primary key for DownlinkLoss: %s", req.PrimaryKey)
	}
	arg := database.UpdateDownlinkLossParams{
		ConfigName:      req.Values[0],
		TestPhaseName:   req.Values[1],
		Profile:         req.Values[2],
		ConfigName_2:    parts[0],
		TestPhaseName_2: parts[1],
	}
	return q.UpdateDownlinkLoss(ctx, arg)
}

func handleInsertDownlinkLoss(q *database.Queries, ctx context.Context, req utils.UpdateRequest) error {
	arg := database.InsertDownlinkLossParams{
		ConfigName:    req.Values[0],
		TestPhaseName: req.Values[1],
		Profile:       req.Values[2],
	}
	return q.InsertDownlinkLoss(ctx, arg)
}

func NullToFloat(val string) sql.NullFloat64 {
	if val == "" {
		return sql.NullFloat64{Valid: false}
	}
	f, err := strconv.ParseFloat(val, 64)
	return sql.NullFloat64{Float64: f, Valid: err == nil}
}

func ToNullString(val string) sql.NullString {
	if val == "" || strings.EqualFold(val, "NULL") {
		return sql.NullString{Valid: false}
	}
	return sql.NullString{String: val, Valid: true}
}
