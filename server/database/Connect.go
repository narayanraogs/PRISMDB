package database

import (
	"database/sql"
	"fmt"
	"os"

	_ "modernc.org/sqlite"
)

var dbObject *Queries
var db *sql.DB

func Connect(path string) bool {
	if !checkIfDatabaseExists(path) {
		return false
	}
	var err error
	db, err = sql.Open("sqlite", path)
	if err != nil {
		fmt.Println("Unable to connect to database", err.Error())
		return false
	}
	db.SetMaxOpenConns(1)
	
	// Sanitize legacy databases by replacing empty strings with NULL in integer columns
	db.Exec("UPDATE TSMConfigurations SET AttnNumber = NULL WHERE AttnNumber = ''")
	
	dbObject = New(db)
	return true
}

func checkIfDatabaseExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}
