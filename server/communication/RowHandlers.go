package communication

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"strings"

	"prismDB/database"
	"prismDB/utils"

	"github.com/gin-gonic/gin"
)

func getRows(c *gin.Context) {
	var req utils.RowDisplayRequest
	var resp utils.RowDetails
	resp.OK = false
	resp.Values = make([]string, 0)

	if err := c.BindJSON(&req); err != nil {
		resp.Message = "Bad Request"
		c.IndentedJSON(http.StatusOK, resp)
		return
	}

	conn, ok := clientMap[req.ID]
	if !ok {
		resp.Message = "Re-Register Database"
		c.IndentedJSON(http.StatusOK, resp)
		return
	}

	q := database.New(conn)
	ctx := context.Background()

	var err error

	switch strings.ToLower(req.TableName) {
	case "spectx":
		err = handleGetSpecTx(q, ctx, req, &resp)
	case "specrx":
		err = handleGetSpecRx(q, ctx, req, &resp)
	case "spectp":
		err = handleGetSpecTp(q, ctx, req, &resp)
	case "tmprofile":
		err = handleGetTMProfile(q, ctx, req, &resp)
	case "updownconverter":
		err = handleGetUpDownConverter(q, ctx, req, &resp)
	case "testphases":
		err = handleGetTestPhases(q, ctx, req, &resp)
	case "devices":
		err = handleGetDevices(q, ctx, req, &resp)
	case "configurations":
		err = handleGetConfigurations(q, ctx, req, &resp)
	case "tsmconfigurations":
		err = handleGetTSMConfigurations(q, ctx, req, &resp)
	case "spectxharmonics":
		err = handleGetSpecTxHarmonics(q, ctx, req, &resp)
	case "spectxsubcarriers":
		err = handleGetSpecTxSubCarriers(q, ctx, req, &resp)
	case "spectpranging":
		err = handleGetSpecTpRanging(q, ctx, req, &resp)
	case "specrxtmtc", "specrxtm":
		err = handleGetSpecRxTMTC(q, ctx, req, &resp)
	case "frequencyprofile":
		err = handleGetFrequencyProfile(q, ctx, req, &resp)
	case "powerprofile":
		err = handleGetPowerProfile(q, ctx, req, &resp)
	case "spectrumprofile":
		err = handleGetSpectrumProfile(q, ctx, req, &resp)
	case "pulseprofile":
		err = handleGetPulseProfile(q, ctx, req, &resp)
	case "trmprofile":
		err = handleGetTRMProfile(q, ctx, req, &resp)
	case "tests":
		err = handleGetTests(q, ctx, req, &resp)
	case "deviceprofile":
		err = handleGetDeviceProfile(q, ctx, req, &resp)
	case "downlinkpowerprofile":
		err = handleGetDownlinkPowerProfile(q, ctx, req, &resp)
	case "lossmeasurementfrequencies":
		err = handleGetLossMeasurementFrequencies(q, ctx, req, &resp)
	case "specpl":
		err = handleGetSpecPL(q, ctx, req, &resp)
	case "uplinkloss":
		err = handleGetUplinkLoss(q, ctx, req, &resp)
	case "downlinkloss":
		err = handleGetDownlinkLoss(q, ctx, req, &resp)
	default:
		err = fmt.Errorf("getRows not implemented for table: %s", req.TableName)
	}

	if err != nil {
		resp.Message = err.Error()
	} else {
		resp.OK = true
	}

	c.IndentedJSON(http.StatusOK, resp)
}

func handleGetSpecTxHarmonics(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	keys := strings.Split(req.PrimaryKey, ":::")
	if len(keys) < 3 {
		return fmt.Errorf("invalid primary key for SpecTxHarmonics: expected TxName:::HarmonicType:::HarmonicsName")
	}

	arg := database.GetSpecTxHarmonicsByKeyParams{
		TxName:        keys[0],
		HarmonicType:  keys[1],
		HarmonicsName: keys[2],
	}

	row, err := q.GetSpecTxHarmonicsByKey(ctx, arg)
	if err != nil {
		return err
	}

	// Client Expects: [TxName, HarmonicType, HarmonicsName, Frequency, Loss]
	resp.Values = append(resp.Values, row.TxName)
	resp.Values = append(resp.Values, row.HarmonicType)
	resp.Values = append(resp.Values, row.HarmonicsName)
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.Frequency))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.TotalLossFromTxToSA))

	return nil
}

func handleGetSpecTxSubCarriers(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	keys := strings.Split(req.PrimaryKey, ":::")
	if len(keys) < 2 {
		return fmt.Errorf("invalid primary key for SpecTxSubCarriers: expected TxName:::SubCarrierName")
	}

	arg := database.GetSpecTxSubCarrierByKeyParams{
		TxName:         keys[0],
		SubCarrierName: keys[1],
	}

	row, err := q.GetSpecTxSubCarrierByKey(ctx, arg)
	if err != nil {
		return err
	}

	// Client Expects: [TxName, SubCarrierName, Frequency, ModIndex, ModIndexDev, AlwaysPresent, PeakFreqDev]
	resp.Values = append(resp.Values, row.TxName)
	resp.Values = append(resp.Values, row.SubCarrierName)
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.Frequency))

	if row.ModIndex.Valid {
		resp.Values = append(resp.Values, fmt.Sprintf("%v", row.ModIndex.Float64))
	} else {
		resp.Values = append(resp.Values, "0.0")
	}

	if row.AllowedModIndexDeviation.Valid {
		resp.Values = append(resp.Values, fmt.Sprintf("%v", row.AllowedModIndexDeviation.Float64))
	} else {
		resp.Values = append(resp.Values, "0.0")
	}

	resp.Values = append(resp.Values, row.AlwaysPresent)

	if row.PeakFrequencyDeviation.Valid {
		resp.Values = append(resp.Values, fmt.Sprintf("%v", row.PeakFrequencyDeviation.Float64))
	} else {
		resp.Values = append(resp.Values, "0.0")
	}

	return nil
}

func handleGetSpecTpRanging(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	keys := strings.Split(req.PrimaryKey, ":::")
	if len(keys) < 2 {
		return fmt.Errorf("invalid primary key for SpecTpRanging: expected TpName:::RangingName")
	}

	arg := database.GetSpecTpRangingByKeyParams{
		TpName:      keys[0],
		RangingName: keys[1],
	}

	row, err := q.GetSpecTpRangingByKey(ctx, arg)
	if err != nil {
		return err
	}

	// Client Expects: [TpName, RangingName, ToneFrequency, UplinkToneMIOnly..., UplinkToneMISim..., TCMISim..., DownlinkMI, AllowedDownlinkMIDev..., AvailableForCommanding]
	resp.Values = append(resp.Values, row.TpName)
	resp.Values = append(resp.Values, row.RangingName)
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.ToneFrequency))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.UplinkToneMIOnlyRanging))

	if row.UplinkToneMISimultaneousCmdAndRanging.Valid {
		resp.Values = append(resp.Values, fmt.Sprintf("%v", row.UplinkToneMISimultaneousCmdAndRanging.Float64))
	} else {
		resp.Values = append(resp.Values, "0.0")
	}

	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.TCMISimultaneousCmdAndRanging))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.DownlinkMI))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.AllowedDownlinkMIDeviation))
	resp.Values = append(resp.Values, row.AvailableForCommanding)

	return nil
}

func handleGetSpecRxTMTC(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetSpecRxTMTCByName(ctx, req.PrimaryKey)
	if err != nil {
		return err
	}

	// Schema: [RxName, LockStatusMnemonic, LockStatusValue, BSLockStatusMnemonic, BSLockStatusValue, AGCMnemonic, LoopStressMnemonic, CommandCounterMnemonic, TestCommandSet, TestCommandReset]
	resp.Values = append(resp.Values, row.RxName)
	resp.Values = append(resp.Values, NullToString(row.LockStatusMnemonic))
	resp.Values = append(resp.Values, NullToString(row.LockStatusValue))
	resp.Values = append(resp.Values, row.BSLockStatusMnemonic)
	resp.Values = append(resp.Values, row.BSLockStatusValue)
	resp.Values = append(resp.Values, row.AGCMnemonic)
	resp.Values = append(resp.Values, NullToString(row.LoopStressMnemonic))
	resp.Values = append(resp.Values, row.CommandCounterMnemonic)
	resp.Values = append(resp.Values, row.TestCommandSet)
	resp.Values = append(resp.Values, row.TestCommandReset)

	return nil
}

func handleGetSpecTx(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetSpecTxByName(ctx, req.PrimaryKey)
	if err != nil {
		return err
	}
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.TxID))
	resp.Values = append(resp.Values, row.TxName)
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.Frequency))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.Power))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.Spurious))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.Harmonics))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.AllowedFrequencyDeviation))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.AllowedPowerDevaition))
	resp.Values = append(resp.Values, row.ModulationScheme)
	resp.Values = append(resp.Values, row.IsBurst)
	if row.BurstTime.Valid {
		resp.Values = append(resp.Values, fmt.Sprintf("%v", row.BurstTime.Float64))
	} else {
		resp.Values = append(resp.Values, "0.0")
	}
	return nil
}

func handleGetSpecRx(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetSpecRxByName(ctx, req.PrimaryKey)
	if err != nil {
		return err
	}
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.ID))
	resp.Values = append(resp.Values, row.RxName)
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.Frequency))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.MaxPower))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.TCSubCarrierFrequency))
	resp.Values = append(resp.Values, row.ModulationScheme)
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.AcquisitionOffset.Float64))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.SweepRange.Float64))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.SweepRate.Float64))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.TCModIndex.Float64))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.FrequencyDeviationFM.Float64))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.CodeRateInMcps.Float64))
	return nil
}

func handleGetSpecTp(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetSpecTpByName(ctx, sql.NullString{String: req.PrimaryKey, Valid: true})
	if err != nil {
		return err
	}
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.TpID))
	resp.Values = append(resp.Values, NullToString(row.TpName))
	resp.Values = append(resp.Values, row.RxName)
	resp.Values = append(resp.Values, row.TxName)
	return nil
}

func handleGetConfigurations(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetConfigurationByName(ctx, req.PrimaryKey)
	if err != nil {
		return err
	}
	// [ConfigName, ConfigType, RxName, TxName, TpName, TSMConfigurationName, CortexIFM, IntermediateFrequency, PayloadName, DeviceProfileName, ProgrammableAttnUsed]
	resp.Values = append(resp.Values, row.ConfigName)
	resp.Values = append(resp.Values, row.ConfigType)
	resp.Values = append(resp.Values, NullToString(row.RxName))
	resp.Values = append(resp.Values, NullToString(row.TxName))
	resp.Values = append(resp.Values, NullToString(row.TpName))
	resp.Values = append(resp.Values, row.TSMConfigurationName)
	if row.CortexIFM.Valid {
		resp.Values = append(resp.Values, row.CortexIFM.String)
	} else {
		resp.Values = append(resp.Values, "A")
	}
	if row.IntermediateFrequency.Valid {
		resp.Values = append(resp.Values, fmt.Sprintf("%v", row.IntermediateFrequency.Int64))
	} else {
		resp.Values = append(resp.Values, "0")
	}
	resp.Values = append(resp.Values, NullToString(row.PayloadName))
	resp.Values = append(resp.Values, row.DeviceProfileName)
	resp.Values = append(resp.Values, NullToString(row.ProgrammableAttnUsed))
	return nil
}

func handleGetTSMConfigurations(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetTSMConfigurationsByName(ctx, req.PrimaryKey)
	if err != nil {
		return err
	}
	// [Name, UplinkToSC, IncludePad, ExcludePad, UplinkToSA, UplinkToPM, TerminateUplink, DownlinkToSA, DownlinkToPM, AttnNumber]
	resp.Values = append(resp.Values, row.Name)
	resp.Values = append(resp.Values, NullToString(row.UplinkToSC))
	resp.Values = append(resp.Values, NullToString(row.IncludePad))
	resp.Values = append(resp.Values, NullToString(row.ExcludePad))
	resp.Values = append(resp.Values, NullToString(row.UplinkToSA))
	resp.Values = append(resp.Values, NullToString(row.UplinkToPM))
	resp.Values = append(resp.Values, NullToString(row.TerminateUplink))
	resp.Values = append(resp.Values, NullToString(row.DownlinkToSA))
	resp.Values = append(resp.Values, NullToString(row.DownlinkToPM))
	if row.AttnNumber.Valid {
		resp.Values = append(resp.Values, fmt.Sprintf("%v", row.AttnNumber.Int64))
	} else {
		resp.Values = append(resp.Values, "0")
	}
	return nil
}

func handleGetFrequencyProfile(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetFrequencyProfileByName(ctx, req.PrimaryKey)
	if err != nil {
		return err
	}
	resp.Values = append(resp.Values, row.Name)
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.MaxFrequency.Float64))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.StepSize.Float64))
	resp.Values = append(resp.Values, row.CommandingRequired)
	resp.Values = append(resp.Values, NullToString(row.DopplerFile))
	return nil
}

func handleGetPowerProfile(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetPowerProfileByName(ctx, req.PrimaryKey)
	if err != nil {
		return err
	}
	resp.Values = append(resp.Values, row.Name)
	resp.Values = append(resp.Values, row.PowerLevels)
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.NoOfCommandsAtThreshold))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.NoOfCommandsAtOtherLevels))
	return nil
}

func handleGetSpectrumProfile(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetSpectrumProfileByName(ctx, req.PrimaryKey)
	if err != nil {
		return err
	}
	resp.Values = append(resp.Values, row.Name)
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.CenterFrequency))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.Span))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.RBW))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.VBW))
	return nil
}

func handleGetPulseProfile(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetPulseProfileByName(ctx, req.PrimaryKey)
	if err != nil {
		return err
	}
	// Mapping all fields for PulseProfile
	resp.Values = append(resp.Values, row.Name)
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.TransientON))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.IQOn))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.AcquisitionTime))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.SweepTime))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.SweepCount))
	resp.Values = append(resp.Values, row.FilterType)
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.FilterBandwidth))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.YTop))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.ThresholdLevel))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.Hysterisis))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.PPMTriggerLevel))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.PPMReferenceLevel))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.PPMYDivision))
	resp.Values = append(resp.Values, row.PPMChannel)
	return nil
}

func handleGetTRMProfile(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetTRMProfileByName(ctx, sql.NullString{String: req.PrimaryKey, Valid: true})
	if err != nil {
		return err
	}
	resp.Values = append(resp.Values, NullToString(row.Name))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.NoOfTRMs))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.TimePerTRMInSecs))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.DelayBeforeFirstReadInSecs))
	return nil
}

func handleGetTests(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetTestByID(ctx, parseInt(req.PrimaryKey))
	if err != nil {
		return err
	}
	resp.Values = append(resp.Values, row.ConfigName)
	resp.Values = append(resp.Values, row.TestType)
	resp.Values = append(resp.Values, row.TestCategory)
	resp.Values = append(resp.Values, NullToString(row.ULProfileName))
	resp.Values = append(resp.Values, NullToString(row.DLProfileName))
	resp.Values = append(resp.Values, NullToString(row.PowerProfileName))
	resp.Values = append(resp.Values, NullToString(row.FrequencyProfileName))
	resp.Values = append(resp.Values, NullToString(row.DownlinkPowerProfileName))
	resp.Values = append(resp.Values, NullToString(row.PulseProfileName))
	resp.Values = append(resp.Values, NullToString(row.TRMProfileName))
	resp.Values = append(resp.Values, NullToString(row.TMProfileName))
	return nil
}

func handleGetDeviceProfile(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetDeviceProfileByName(ctx, req.PrimaryKey)
	if err != nil {
		return err
	}
	resp.Values = append(resp.Values, row.DeviceProfileName)
	resp.Values = append(resp.Values, NullToString(row.SAName))
	resp.Values = append(resp.Values, NullToString(row.VSAName))
	resp.Values = append(resp.Values, NullToString(row.PMName))
	resp.Values = append(resp.Values, NullToString(row.PPMName))
	resp.Values = append(resp.Values, NullToString(row.TSMName))
	resp.Values = append(resp.Values, NullToString(row.GTxName))
	resp.Values = append(resp.Values, NullToString(row.SGName))
	resp.Values = append(resp.Values, NullToString(row.VSGName))
	return nil
}

func handleGetDownlinkPowerProfile(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetDownlinkPowerProfileByName(ctx, sql.NullString{String: req.PrimaryKey, Valid: true})
	if err != nil {
		return err
	}
	resp.Values = append(resp.Values, NullToString(row.Name))
	resp.Values = append(resp.Values, row.PMChannel)
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.OccupiedBW))
	return nil
}

func handleGetLossMeasurementFrequencies(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetLossMeasurementFrequenciesByDescription(ctx, req.PrimaryKey)
	if err != nil {
		return err
	}
	// [Description, Frequency]
	resp.Values = append(resp.Values, row.Description)
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.Frequency))
	return nil
}

func handleGetSpecPL(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	keys := strings.Split(req.PrimaryKey, ":::")
	if len(keys) < 2 {
		return fmt.Errorf("invalid primary key for SpecPL: expected ConfigName:::ResolutionMode")
	}

	arg := database.GetSpecPLByKeyParams{
		ConfigName:     keys[0],
		ResolutionMode: ToNullString(keys[1]),
	}

	row, err := q.GetSpecPLByKey(ctx, arg)
	if err != nil {
		return err
	}
	// Mapping SpecPL fields...
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.SpecID))
	resp.Values = append(resp.Values, row.ConfigName)
	resp.Values = append(resp.Values, NullToString(row.ResolutionMode))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.OnTime))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.CenterFrequency))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.UplinkPower))
	resp.Values = append(resp.Values, NullFloatToString(row.PeakPower))
	resp.Values = append(resp.Values, NullFloatToString(row.PeakPowerTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.AveragePower))
	resp.Values = append(resp.Values, NullFloatToString(row.AveragePowerTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.DutyCycle))
	resp.Values = append(resp.Values, NullFloatToString(row.DutyCycleTolerance))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.PulsePeriod))
	resp.Values = append(resp.Values, NullFloatToString(row.PulsePeriodTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.ReplicaPeriod))
	resp.Values = append(resp.Values, NullFloatToString(row.ReplicaPeriodTolerance))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.PulseWidth))
	resp.Values = append(resp.Values, NullFloatToString(row.PulseWidthTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.PulseSeperation))
	resp.Values = append(resp.Values, NullFloatToString(row.PulseSeperationTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.RiseTime))
	resp.Values = append(resp.Values, NullFloatToString(row.RiseTimeTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.FallTime))
	resp.Values = append(resp.Values, NullFloatToString(row.FallTimeTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.AverageTxPower))
	resp.Values = append(resp.Values, NullFloatToString(row.AverageTxPowerTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.ChirpBandwidth))
	resp.Values = append(resp.Values, NullFloatToString(row.ChirpBandwidthTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.RepetitionRate))
	resp.Values = append(resp.Values, NullFloatToString(row.RepetitionRateTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.ReplicaRate))
	resp.Values = append(resp.Values, NullFloatToString(row.ReplicaRateTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.FrequencyShift))
	resp.Values = append(resp.Values, NullFloatToString(row.FrequencyShiftTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.Droop))
	resp.Values = append(resp.Values, NullFloatToString(row.DroopTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.Phase))
	resp.Values = append(resp.Values, NullFloatToString(row.PhaseTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.Overshoot))
	resp.Values = append(resp.Values, NullFloatToString(row.OvershootTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.ChirpRate))
	resp.Values = append(resp.Values, NullFloatToString(row.ChirpRateTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.ChirpRateDeviation))
	resp.Values = append(resp.Values, NullFloatToString(row.ChirpRateDeviationTolerance))
	resp.Values = append(resp.Values, NullFloatToString(row.Ripple))
	resp.Values = append(resp.Values, NullFloatToString(row.RippleTolerance))
	return nil
}

func handleGetTMProfile(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetTMProfileByName(ctx, req.PrimaryKey)
	if err != nil {
		return err
	}
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.ID))
	resp.Values = append(resp.Values, row.Name)
	resp.Values = append(resp.Values, NullToString(row.PreRequisiteTM))
	resp.Values = append(resp.Values, NullToString(row.LogTM))
	return nil
}

func handleGetUpDownConverter(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetUpDownConverterByName(ctx, req.PrimaryKey)
	if err != nil {
		return err
	}
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.ID))
	resp.Values = append(resp.Values, row.Name)
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.InputFrequency))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.OutputFrequency))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.MaxPowerCable))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.MinPowerCable))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.MaxPowerRadiated.Float64))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.MinPowerRadiated.Float64))
	return nil
}

func handleGetTestPhases(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetTestPhaseByName(ctx, req.PrimaryKey)
	if err != nil {
		return err
	}
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.ID))
	resp.Values = append(resp.Values, row.Name)
	resp.Values = append(resp.Values, NullToString(row.CreationDate))
	resp.Values = append(resp.Values, NullToString(row.CreationTime))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.Selected))
	return nil
}

func handleGetDevices(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	row, err := q.GetDevicesByName(ctx, req.PrimaryKey)
	if err != nil {
		return err
	}
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.ID))
	resp.Values = append(resp.Values, row.DeviceName)
	resp.Values = append(resp.Values, row.DeviceMake)
	resp.Values = append(resp.Values, row.DeviceType)
	resp.Values = append(resp.Values, row.IPAddress)
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.ControlPort))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.AlternateControlPort.Int64))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.ReadPort.Int64))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.DopplerPort.Int64))
	resp.Values = append(resp.Values, fmt.Sprintf("%v", row.TimeoutInMillisecs))
	return nil
}

func handleGetUplinkLoss(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	parts := strings.Split(req.PrimaryKey, ":::")
	if len(parts) != 2 {
		return fmt.Errorf("invalid primary key for UplinkLoss: %s", req.PrimaryKey)
	}
	row, err := q.GetUplinkLossByKey(ctx, database.GetUplinkLossByKeyParams{
		ConfigName:    parts[0],
		TestPhaseName: parts[1],
	})
	if err != nil {
		return err
	}
	// [ConfigName, TestPhaseName, Profile]
	resp.Values = append(resp.Values, row.ConfigName)
	resp.Values = append(resp.Values, row.TestPhaseName)
	resp.Values = append(resp.Values, row.Profile)
	return nil
}

func handleGetDownlinkLoss(q *database.Queries, ctx context.Context, req utils.RowDisplayRequest, resp *utils.RowDetails) error {
	parts := strings.Split(req.PrimaryKey, ":::")
	if len(parts) != 2 {
		return fmt.Errorf("invalid primary key for DownlinkLoss: %s", req.PrimaryKey)
	}
	row, err := q.GetDownlinkLossByKey(ctx, database.GetDownlinkLossByKeyParams{
		ConfigName:    parts[0],
		TestPhaseName: parts[1],
	})
	if err != nil {
		return err
	}
	resp.Values = append(resp.Values, row.ConfigName)
	resp.Values = append(resp.Values, row.TestPhaseName)
	resp.Values = append(resp.Values, row.Profile)
	return nil
}

func NullFloatToString(nf sql.NullFloat64) string {
	if nf.Valid {
		return fmt.Sprintf("%v", nf.Float64)
	}
	return ""
}
