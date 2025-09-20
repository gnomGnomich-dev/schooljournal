// main.go
package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/gin-gonic/gin"
	"server/db"
	"server/handlers"
)

func main() {
	// Подключение к БД
	connString := os.Getenv("DB_CONN")
	if connString == "" {
		connString = `server=localhost,1433;user id=administrator;password=Ghbdtn123;database=schoolJournal;encrypt=disable;trustservercertificate=true;`
	}

	if err := db.InitDB(connString); err != nil {
		log.Fatal("Failed to initialize database: ", err)
	}
	defer db.CloseDB()

	// Создаем роутер
	r := gin.Default()

	// Роуты
	r.POST("/api/teachers", handlers.AddTeacher)

	// Graceful shutdown
	go func() {
		if err := r.Run(":8080"); err != nil {
			log.Fatal("Server failed to start: ", err)
		}
	}()

	log.Println("Server started on http://localhost:8080")

	// Ожидание SIGINT (Ctrl+C)
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")
}