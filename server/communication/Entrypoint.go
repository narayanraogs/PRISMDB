package communication

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"prismDB/database"
	"prismDB/utils"

	"github.com/gin-gonic/gin"
	_ "modernc.org/sqlite"
)

var clientMap = make(map[string]*sql.DB)

func Init(r *gin.Engine) {
	r.POST("/register", registerClient)
	r.POST("/getCategories", getCategories)
	r.POST("/getTables", getTables)
	r.POST("/updateRow", updateRow)
	r.POST("/addRow", addRow)
	r.POST("/deleteRow", deleteRow)
	r.POST("/getValues", getValues)
	r.POST("/getRows", getRows)
	r.POST("/getSingleValue", getSingleValue)
	r.POST("/validate", validateDatabase)
	r.POST("/validateDB", validateDatabase)
	r.POST("/autoPopulate", autoPopulate)
}

func registerClient(c *gin.Context) {
	var clientID utils.DBRequest
	var ack utils.Ack
	ack.OK = false

	if err := c.BindJSON(&clientID); err != nil {
		ack.Message = "Bad Request"
		c.IndentedJSON(http.StatusOK, ack)
		return
	}

	var dbPath = clientID.DBName
	if clientID.FromConfig {
		dbPath = utils.Config.Database.DBPath
		if dbPath == "" {
			ack.Message = "Cannot read Configuration file"
			c.IndentedJSON(http.StatusOK, ack)
			return
		}
	}

	// Open the database connection
	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		ack.Message = fmt.Sprintf("Failed to open database: %v", err)
		c.IndentedJSON(http.StatusOK, ack)
		return
	}

	// Verify connection
	if err := db.Ping(); err != nil {
		ack.Message = fmt.Sprintf("Failed to connect to database: %v", err)
		c.IndentedJSON(http.StatusOK, ack)
		return
	}

	// Store the connection
	clientMap[clientID.ID] = db

	ack.OK = true
	ack.Message = "Registered Successfully"
	c.IndentedJSON(http.StatusOK, ack)
}

func getCategories(c *gin.Context) {
	var clientID utils.ClientID
	var category utils.Categories
	category.SingleCategories = make([]utils.SingleCategoryDetails, 0)

	if err := c.BindJSON(&clientID); err != nil {
		category.OK = false
		category.Message = "Bad Request"
		c.IndentedJSON(http.StatusOK, category)
		return
	}

	conn, ok := clientMap[clientID.ID]
	if !ok {
		category.OK = false
		category.Message = "Re-Register Database"
		c.IndentedJSON(http.StatusOK, category)
		return
	}

	q := database.New(conn)
	ctx := context.Background()

	// Helper to add category details
	addCategory := func(name string, countFunc func(context.Context) (int64, error)) {
		count, err := countFunc(ctx)
		if err == nil {
			category.SingleCategories = append(category.SingleCategories, utils.SingleCategoryDetails{
				CategoryName: name,
				Items:        int(count),
			})
		} else {
			// Log error or handle it? For now, we skip or add with 0/error
			// fmt.Println("Error getting count for", name, err)
		}
	}

	// Add all categories/tables
	addCategory("Configurations", q.GetConfigurationsCount)
	addCategory("Devices", q.GetDevicesCount)
	addCategory("DeviceProfile", q.GetDeviceProfileCount)
	addCategory("DownlinkLoss", q.GetDownlinkLossCount)
	addCategory("DownlinkPowerProfile", q.GetDownlinkPowerProfileCount)
	addCategory("FrequencyProfile", q.GetFrequencyProfileCount)
	addCategory("LossMeasurementFrequencies", q.GetLossMeasurementFrequenciesCount)
	addCategory("PowerProfile", q.GetPowerProfileCount)
	addCategory("PulseProfile", q.GetPulseProfileCount)
	addCategory("SpecPL", q.GetSpecPLCount)
	addCategory("SpecRx", q.GetSpecRxCount)
	addCategory("SpecRxTMTC", q.GetSpecRxTMTCCount)
	addCategory("SpecTp", q.GetSpecTpCount)
	addCategory("SpecTpRanging", q.GetSpecTpRangingCount)
	addCategory("SpectrumProfile", q.GetSpectrumProfileCount)
	addCategory("SpecTx", q.GetSpecTxCount)
	addCategory("SpecTxHarmonics", q.GetSpecTxHarmonicsCount)
	addCategory("SpecTxSubCarriers", q.GetSpecTxSubCarriersCount)
	addCategory("TestPhases", q.GetTestPhasesCount)
	addCategory("Tests", q.GetTestsCount)
	addCategory("TMProfile", q.GetTMProfileCount)
	addCategory("TRMProfile", q.GetTRMProfileCount)
	addCategory("TSMConfigurations", q.GetTSMConfigurationsCount)
	addCategory("UpDownConverter", q.GetUpDownConverterCount)
	addCategory("UplinkLoss", q.GetUplinkLossCount)

	category.OK = true
	category.Message = ""
	c.IndentedJSON(http.StatusOK, category)
}

func getTables(c *gin.Context) {
	var tableRequest utils.TableDisplayRequest
	var tableDetails utils.TableDisplayDetails
	// Initialize default response
	tableDetails.OK = false
	tableDetails.Message = ""

	if err := c.BindJSON(&tableRequest); err != nil {
		tableDetails.Message = "Bad Request"
		c.IndentedJSON(http.StatusOK, tableDetails)
		return
	}

	conn, ok := clientMap[tableRequest.ID]
	if !ok {
		tableDetails.Message = "Re-Register Database"
		c.IndentedJSON(http.StatusOK, tableDetails)
		return
	}

	details, err := getTableDetails(conn, tableRequest.TableName)
	if err != nil {
		tableDetails.Message = err.Error()
	} else {
		tableDetails = details
		tableDetails.OK = true
	}

	c.IndentedJSON(http.StatusOK, tableDetails)
}

func validateDatabase(c *gin.Context) {
	var clientID utils.ClientID
	var result utils.ValidationResult
	result.OK = false

	if err := c.BindJSON(&clientID); err != nil {
		result.Message = "Bad Request"
		c.IndentedJSON(http.StatusOK, result)
		return
	}

	conn, ok := clientMap[clientID.ID]
	if !ok {
		result.Message = "Re-Register Database"
		c.IndentedJSON(http.StatusOK, result)
		return
	}

	result = Validate(conn)
	c.IndentedJSON(http.StatusOK, result)
}

func autoPopulate(c *gin.Context) {
	var auto utils.AutoPopulate
	var ack utils.Ack
	ack.OK = false

	if err := c.BindJSON(&auto); err != nil {
		ack.Message = "Bad Request"
		c.IndentedJSON(http.StatusOK, ack)
		return
	}

	ack = Create(auto)

	if ack.OK {
		// Open the database connection to register the newly created DB for future commands
		db, err := sql.Open("sqlite", auto.DBPath)
		if err == nil {
			if err := db.Ping(); err == nil {
				clientMap["client_1"] = db // Register it automatically for convenience since CreateView simulates "client_1" on success
			}
		}
	}

	c.IndentedJSON(http.StatusOK, ack)
}
