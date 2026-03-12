package utils

type DBRequest struct {
	ID         string
	DBName     string
	Create     bool
	FromConfig bool
}

type Ack struct {
	OK      bool
	Message string
}

type ClientID struct {
	ID string
}

type RenameRequest struct {
	ID        string
	Operation string
	Type      string
	OldName   string
	NewName   string
}

type Categories struct {
	SingleCategories []SingleCategoryDetails
	OK               bool
	Message          string
}

type SingleCategoryDetails struct {
	CategoryName string
	Items        int
}

type TableDisplayRequest struct {
	ID        string
	TableName string
}

type TableDisplayDetails struct {
	TableName  string
	PrimaryKey []string
	Header     []string
	Rows       []Row
	OK         bool
	Message    string
}

type Row struct {
	Details []string
}

type RowDisplayRequest struct {
	ID         string
	TableName  string
	PrimaryKey string
}

type RowDetails struct {
	Values  []string
	OK      bool
	Message string
}

type ValueRequest struct {
	ID  string
	Key string
}

type ValueResponse struct {
	Values  []string
	OK      bool
	Message string
}

type SingleValueResponse struct {
	Values  string
	OK      bool
	Message string
}

type UpdateRequest struct {
	ID         string
	TableName  string
	PrimaryKey string
	Values     []string
}

type ValidationResult struct {
	SingleTables []SingleTableDetails
	OK           bool
	Message      string
}

type SingleTableDetails struct {
	TableName   string
	Items       int
	Errors      int
	Warnings    int
	ErrorList   []string
	WarningList []string
}

type AutoPopulate struct {
	DBPath        string
	RxNames       []string
	RxFrequencies []float64
	RxModulation  []string
	TxNames       []string
	TxFrequencies []float64
	TxPowers      []float64
	TxModulation  []string
	TPNames       []string
	TPRxNames     []string
	TPTxNames     []string
	PlNames       []string
	ConfigNames   []string
	ConfigTypes   []string
	ConfigRxNames []string
	ConfigTxNames []string
	ConfigTPNames []string
	ConfigPlNames []string
	Create        bool
	OK            bool
	Message       string
}
