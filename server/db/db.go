package db

import (
	"database/sql"
	"fmt"
	"log"
	"time"
	
	_ "github.com/denisenkom/go-mssqldb"
)

var DB *sql.DB

func InitDB(connString string) error {
	var err error
	DB, err = sql.Open("sqlserver", connString)
	if err != nil {
		return fmt.Errorf("failed to open database: %w", err)
	}
	
	DB.SetMaxOpenConns(25)
	DB.SetMaxIdleConns(25)
	DB.SetConnMaxLifetime(5 * time.Minute)
	
	if err = DB.Ping(); err != nil {
		return fmt.Errorf("failed to ping database: %w", err)
	}
	
	log.Println("Successfully connected to SQL Server")
	return nil
}

func CloseDB() {
	if DB != nil {
		DB.Close()
		log.Println("Database connection closed")
	}
}