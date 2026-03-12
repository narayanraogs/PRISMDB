package communication

import "database/sql"

func copyUplinkLosses(db *sql.DB, from string, to string) bool {
	query := "Select * from UplinkLoss where TestPhaseName like ?"
	rows, err := db.Query(query, from)
	if err != nil {
		return false
	}
	losses, ok := readUplinkLoss(rows)
	if !ok {
		return false
	}
	rows.Close()
	tx, err := db.Begin()
	if err != nil {
		return false
	}
	queryDel := "Delete from UplinkLoss where TestPhaseName like ?"
	_, err = tx.Exec(queryDel, to)
	if err != nil {
		tx.Rollback()
		return false
	}
	for _, loss := range losses {
		query := "Insert into UplinkLoss (ConfigName, TestPhaseName, Profile) values (?, ?, ?)"
		_, err = tx.Exec(query, loss.configName, to, loss.profile)
		if err != nil {
			tx.Rollback()
			return false
		}
	}
	err = tx.Commit()
	return err == nil
}

func copyDownlinkLosses(db *sql.DB, from string, to string) bool {
	query := "Select * from DownlinkLoss where TestPhaseName like ?"
	rows, err := db.Query(query, from)
	if err != nil {
		return false
	}
	losses, ok := readDownlinkLoss(rows)
	if !ok {
		return false
	}
	rows.Close()
	tx, err := db.Begin()
	if err != nil {
		return false
	}
	queryDel := "Delete from DownlinkLoss where TestPhaseName like ?"
	_, err = tx.Exec(queryDel, to)
	if err != nil {
		tx.Rollback()
		return false
	}
	for _, loss := range losses {
		query := "Insert into DownlinkLoss (ConfigName, TestPhaseName, Profile) values (?, ?, ?)"
		_, err = tx.Exec(query, loss.configName, to, loss.profile)
		if err != nil {
			tx.Rollback()
			return false
		}
	}
	err = tx.Commit()
	return err == nil
}
