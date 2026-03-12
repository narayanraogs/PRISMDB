package communication

import (
	"context"
	"net/http"
	"prismDB/database"
	"prismDB/utils"
	"strings"

	"github.com/gin-gonic/gin"
)

func getValues(c *gin.Context) {
	var req utils.ValueRequest
	var resp utils.ValueResponse
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

	switch req.Key {
	case "TxNames":
		txList, err := q.ListSpecTx(ctx)
		if err != nil {
			resp.Message = err.Error()
		} else {
			for _, tx := range txList {
				resp.Values = append(resp.Values, tx.TxName)
			}
			resp.OK = true
		}
	case "RxNames":
		rxList, err := q.ListSpecRx(ctx)
		if err != nil {
			resp.Message = err.Error()
		} else {
			for _, rx := range rxList {
				resp.Values = append(resp.Values, rx.RxName)
			}
			resp.OK = true
		}
	case "TPNames":
		tpList, err := q.ListSpecTp(ctx)
		if err != nil {
			resp.Message = err.Error()
		} else {
			for _, tp := range tpList {
				if tp.TpName.Valid {
					resp.Values = append(resp.Values, tp.TpName.String)
				}
			}
			resp.OK = true
		}
	case "PLNames":
		plList, err := q.ListSpecPL(ctx)
		if err != nil {
			resp.Message = err.Error()
		} else {
			for _, pl := range plList {
				resp.Values = append(resp.Values, pl.ConfigName)
			}
			resp.OK = true
		}
	case "TSMConfigurations":
		tsmList, err := q.ListTSMConfigurations(ctx)
		if err != nil {
			resp.Message = err.Error()
		} else {
			for _, tsm := range tsmList {
				resp.Values = append(resp.Values, tsm.Name)
			}
			resp.OK = true
		}
	case "PLConfigNames":
		cfgList, err := q.ListConfigurations(ctx)
		if err != nil {
			resp.Message = err.Error()
		} else {
			for _, cfg := range cfgList {
				if cfg.ConfigType == "PL" {
					resp.Values = append(resp.Values, cfg.ConfigName)
				}
			}
			resp.OK = true
		}
	case "UplinkConfigs":
		cfgList, err := q.ListConfigurations(ctx)
		if err != nil {
			resp.Message = err.Error()
		} else {
			for _, cfg := range cfgList {
				if cfg.ConfigType == "Rx" || cfg.ConfigType == "Tp" {
					resp.Values = append(resp.Values, cfg.ConfigName)
				}
			}
			if len(resp.Values) == 0 {
				for _, cfg := range cfgList {
					if cfg.ConfigType != "PL" {
						resp.Values = append(resp.Values, cfg.ConfigName)
					}
				}
			}
			resp.OK = true
		}
	case "DownlinkConfigs":
		cfgList, err := q.ListConfigurations(ctx)
		if err != nil {
			resp.Message = err.Error()
		} else {
			for _, cfg := range cfgList {
				if cfg.ConfigType == "Tx" || cfg.ConfigType == "Tp" {
					resp.Values = append(resp.Values, cfg.ConfigName)
				}
			}
			if len(resp.Values) == 0 {
				for _, cfg := range cfgList {
					if cfg.ConfigType != "PL" {
						resp.Values = append(resp.Values, cfg.ConfigName)
					}
				}
			}
			resp.OK = true
		}
	case "TestPhases":
		tpList, err := q.ListTestPhases(ctx)
		if err != nil {
			resp.Message = err.Error()
		} else {
			for _, tp := range tpList {
				resp.Values = append(resp.Values, tp.Name)
			}
			resp.OK = true
		}
	default:
		resp.Message = "Unknown Key"
	}

	c.IndentedJSON(http.StatusOK, resp)
}

func getSingleValue(c *gin.Context) {
	var req utils.ValueRequest
	var resp utils.SingleValueResponse
	resp.OK = false

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

	if strings.HasPrefix(req.Key, "TxModulation:::") {
		txName := strings.TrimPrefix(req.Key, "TxModulation:::")
		tx, err := q.GetSpecTxByName(ctx, txName)
		if err != nil {
			resp.Message = err.Error()
		} else {
			resp.Values = tx.ModulationScheme
			resp.OK = true
		}
	} else if req.Key == "SelectedTestPhase" {
		tp, err := q.GetSelectedTestPhaseName(ctx)
		if err != nil {
			resp.Message = err.Error()
		} else {
			resp.Values = tp
			resp.OK = true
		}
	} else {
		resp.Message = "Unknown Key"
	}

	c.IndentedJSON(http.StatusOK, resp)
}
