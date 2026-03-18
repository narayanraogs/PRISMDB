package communication

import (
	"context"
	"database/sql"
	"fmt"
	"prismDB/database"
	"prismDB/utils"
	"reflect"
	"strings"
)

func getTableDetails(db *sql.DB, tableName string) (utils.TableDisplayDetails, error) {
	var details utils.TableDisplayDetails
	details.TableName = tableName
	details.OK = false
	details.Rows = make([]utils.Row, 0)
	details.Header = make([]string, 0)
	details.PrimaryKey = make([]string, 0)

	q := database.New(db)
	ctx := context.Background()

	return getTableDataWait(q, ctx, tableName)
}

func getTableDataWait(q *database.Queries, ctx context.Context, tableName string) (utils.TableDisplayDetails, error) {
	var details utils.TableDisplayDetails
	details.TableName = tableName
	details.Rows = make([]utils.Row, 0)
	details.Header = make([]string, 0)
	details.PrimaryKey = make([]string, 0)

	convert := func(slice interface{}) {
		val := reflect.ValueOf(slice)
		if val.Kind() != reflect.Slice {
			return
		}

		// Get Headers from struct type (handles empty slice case)
		elemType := val.Type().Elem()
		if elemType.Kind() == reflect.Struct {
			for i := 0; i < elemType.NumField(); i++ {
				details.Header = append(details.Header, elemType.Field(i).Name)
			}
		}

		if val.Len() == 0 {
			details.OK = true
			return
		}

		// Get Rows
		for i := 0; i < val.Len(); i++ {
			rowVal := val.Index(i)
			var rowStrings []string
			for j := 0; j < rowVal.NumField(); j++ {
				field := rowVal.Field(j)

				// Handle pointers (sql.NullString, etc often appear as struct fields or ptrs)
				if field.Kind() == reflect.Ptr {
					if field.IsNil() {
						rowStrings = append(rowStrings, "NULL")
						continue
					} else {
						field = field.Elem()
					}
				}

				// Handle scanner types like sql.NullString
				if field.Kind() == reflect.Struct {
					// Check for Valid field convention (sql.NullString etc)
					validField := field.FieldByName("Valid")
					if validField.IsValid() && validField.Kind() == reflect.Bool {
						if !validField.Bool() {
							rowStrings = append(rowStrings, "NULL")
							continue
						}
						// If valid, use the Value-like field (String, Int64, etc)
						// Usually field 0 is the value
						valField := field.Field(0)
						if valField.IsValid() {
							rowStrings = append(rowStrings, fmt.Sprintf("%v", valField.Interface()))
							continue
						}
					}
				}

				rowStrings = append(rowStrings, fmt.Sprintf("%v", field.Interface()))
			}
			details.Rows = append(details.Rows, utils.Row{Details: rowStrings})
			// Build Primary Key
			pk := ""
			l := strings.ToLower(tableName)
			switch {
			case l == "specpl":
				if len(rowStrings) > 2 {
					pk = rowStrings[1] + ":::" + rowStrings[2]
				}
			case l == "spectpranging":
				if len(rowStrings) > 2 {
					pk = rowStrings[0] + ":::" + rowStrings[2]
				}
			case l == "spectxharmonics":
				if len(rowStrings) > 3 {
					pk = rowStrings[0] + ":::" + rowStrings[2] + ":::" + rowStrings[3]
				}
			case l == "spectxsubcarriers":
				if len(rowStrings) > 2 {
					pk = rowStrings[0] + ":::" + rowStrings[2]
				}
			case l == "uplinkloss" || l == "downlinkloss":
				if len(rowStrings) > 1 {
					pk = rowStrings[0] + ":::" + rowStrings[1]
				}
			case l == "spectx" || l == "specrx" || l == "spectp" || l == "configurations" || l == "devices" || l == "deviceprofile":
				// These have ID at 0 and Name at 1. We use Name as PK for handlers.
				if len(rowStrings) > 1 {
					pk = rowStrings[1]
				} else if len(rowStrings) > 0 {
					pk = rowStrings[0]
				}
			default:
				if len(rowStrings) > 0 {
					pk = rowStrings[0]
				}
			}
			details.PrimaryKey = append(details.PrimaryKey, pk)
		}
		details.OK = true
	}

	var data interface{}
	var err error

	switch strings.ToLower(tableName) {
	case "spectx":
		data, err = q.ListSpecTx(ctx)
	case "spectxharmonics":
		data, err = q.ListSpecTxHarmonics(ctx)
	case "spectxsubcarriers":
		data, err = q.ListSpecTxSubCarriers(ctx)
	case "specrx":
		data, err = q.ListSpecRx(ctx)
	case "specrxtmtc":
		data, err = q.ListSpecRxTMTC(ctx)
	case "spectp":
		data, err = q.ListSpecTp(ctx)
	case "spectpranging":
		data, err = q.ListSpecTpRanging(ctx)
	case "testphases":
		data, err = q.ListTestPhases(ctx)
	case "uplinkloss":
		data, err = q.ListUplinkLoss(ctx)
	case "downlinkloss":
		data, err = q.ListDownlinkLoss(ctx)
	case "devices":
		data, err = q.ListDevices(ctx)
	case "deviceprofile":
		data, err = q.ListDeviceProfile(ctx)
	case "frequencyprofile":
		data, err = q.ListFrequencyProfile(ctx)
	case "powerprofile":
		data, err = q.ListPowerProfile(ctx)
	case "spectrumprofile":
		data, err = q.ListSpectrumProfile(ctx)
	case "tmprofile":
		data, err = q.ListTMProfile(ctx)
	case "tsmconfigurations":
		data, err = q.ListTSMConfigurations(ctx)
	case "configurations":
		data, err = q.ListConfigurations(ctx)
	case "tests":
		data, err = q.ListTests(ctx)
	case "updownconverter":
		data, err = q.ListUpDownConverter(ctx)
	case "downlinkpowerprofile":
		data, err = q.ListDownlinkPowerProfile(ctx)
	case "lossmeasurementfrequencies":
		data, err = q.ListLossMeasurementFrequencies(ctx)
	case "pulseprofile":
		data, err = q.ListPulseProfile(ctx)
	case "specpl":
		data, err = q.ListSpecPL(ctx)
	case "trmprofile":
		data, err = q.ListTRMProfile(ctx)
	default:
		return details, fmt.Errorf("unknown table: %s", tableName)
	}

	if err != nil {
		return details, err
	}

	convert(data)
	return details, nil
}
