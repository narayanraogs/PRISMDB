import sys

with open('server/communication/AutoPopulate.go', 'r') as f:
    lines = f.readlines()

new_lines = []
in_create = False
inserted_deletes = False

for line in lines:
    if line.startswith('func Create(auto utils.AutoPopulate) utils.Ack {'):
        in_create = True
    
    if in_create and not inserted_deletes and 'for i := range auto.RxNames {' in line:
        deletes = """
	for _, name := range auto.DeletedRxNames {
		db.Exec("DELETE FROM SpecRx WHERE RxName = ?", name)
	}
	for _, name := range auto.DeletedTxNames {
		db.Exec("DELETE FROM SpecTx WHERE TxName = ?", name)
	}
	for _, name := range auto.DeletedTPNames {
		db.Exec("DELETE FROM SpecTp WHERE TpName = ?", name)
	}
	for _, name := range auto.DeletedPlNames {
		db.Exec("DELETE FROM SpecPL WHERE ConfigName IN (SELECT ConfigName FROM Configurations WHERE PayloadName = ?)", name)
		db.Exec("DELETE FROM Configurations WHERE PayloadName = ?", name)
	}
	for _, name := range auto.DeletedConfigNames {
		db.Exec("DELETE FROM Configurations WHERE ConfigName = ?", name)
	}

"""
        new_lines.append(deletes)
        inserted_deletes = True
        
    line = line.replace('INSERT OR IGNORE INTO', 'INSERT OR REPLACE INTO')
    new_lines.append(line)

with open('server/communication/AutoPopulate.go', 'w') as f:
    f.writelines(new_lines)
