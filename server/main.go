package main

import (
	"embed"
	"flag"
	"fmt"
	"io/fs"
	"net/http"
	"os"
	"path/filepath"

	"prismDB/communication"
	"prismDB/database"
	"prismDB/logger"
	"prismDB/utils"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

var cfgPath = flag.String("cfg", "~/prism/config/config.json", "Config File Path")
var portNo = flag.Int("port", 8085, "Port Number")

func init() {
	flag.Parse()
}

//go:embed web
var embeddedFiles embed.FS

func main() {

	ok := utils.ReadConfiguration(*cfgPath)
	if !ok {
		return
	}
	// utils.ReadSelectionParams()
	logPath := filepath.Join(utils.Config.BaseFolder, "log")
	logger.InitializeLog(logPath)
	connectToDatabases()

	webFS, err := fs.Sub(embeddedFiles, "web")
	if err != nil {
		fmt.Println(err)
	}

	router := gin.Default()
	router.Use(cors.Default())

	// Initialize communication routes
	communication.Init(router)

	router.NoRoute(func(c *gin.Context) {
		http.FileServer(http.FS(webFS)).ServeHTTP(c.Writer, c.Request)
	})

	fmt.Printf("Server started on PORT %d\n", *portNo)
	err = router.Run(fmt.Sprintf(":%d", *portNo))
	if err != nil {
		fmt.Println(err)
	}
}

func connectToDatabases() {
	ok := database.Connect(utils.Config.Database.DBPath)
	if !ok {
		fmt.Println("Cannot Connect to Database")
		os.Exit(0)
	}
}
