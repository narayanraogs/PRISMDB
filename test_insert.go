package main
import (
	"context"
	"fmt"
	"prismDB/database"
	"database/sql"
	_ "github.com/mattn/go-sqlite3"
)
func main() {
	db, err := sql.Open("sqlite3", "server/prism.db")
	if err != nil { fmt.Println(err); return }
	defer db.Close()
	q := database.New(db)
	err = q.InsertUplinkLoss(context.Background(), database.InsertUplinkLossParams{
		ConfigName: "TestConfig",
		TestPhaseName: "TestPhase",
		Profile: "",
	})
	if err != nil { fmt.Println(err); return }
	fmt.Println("Success")
}
