// handlers/teacher.go
package handlers

import (
	"database/sql"
	// "encoding/json"
	"net/http"

	"github.com/gin-gonic/gin"
	"server/db"
)

type AddTeacherRequest struct {
	Email     string `json:"email" binding:"required,email"`
	Phone     string `json:"phone" binding:"required"`
	Fullname  string `json:"fullname" binding:"required"`
	Subject   string `json:"subject_name" binding:"required"`
	Education string `json:"education"`
	Experience int    `json:"experience_years"`
	HireDate  string `json:"hire_date"` // YYYY-MM-DD
	Gender    string `json:"gender_name"`
}

type AddTeacherResponse struct {
	Message          string `json:"message"`
	GeneratedPassword string `json:"generated_password"`
}

func AddTeacher(c *gin.Context) {
	var req AddTeacherRequest

	// Валидация входных данных
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	// Подготавливаем OUTPUT параметры
	var generatedPassword string
	// var userID int

	// Вызываем хранимую процедуру
	_, err := db.DB.ExecContext(c, `
		EXEC add_teacher 
			@email = @email,
			@phone = @phone,
			@fullname = @fullname,
			@subject_name = @subject,
			@education = @education,
			@experience_years = @experience,
			@hire_date = @hire_date,
			@gender_name = @gender,
			@generated_password = @pwd OUTPUT
	`,
		sql.Named("email", req.Email),
		sql.Named("phone", req.Phone),
		sql.Named("fullname", req.Fullname),
		sql.Named("subject", req.Subject),
		sql.Named("education", req.Education),
		sql.Named("experience", req.Experience),
		sql.Named("hire_date", req.HireDate),
		sql.Named("gender", req.Gender),
		sql.Named("pwd", sql.Out{Dest: &generatedPassword}),
	)

	if err != nil {
		// Проверяем ошибки бизнес-логики (RAISERROR из процедуры)
		if isSQLError(err) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Database error", "details": err.Error()})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create teacher", "details": err.Error()})
		}
		return
	}
	
	// TODO: Если надо, то возвратим userId

	resp := AddTeacherResponse{
		Message:          "Teacher created successfully",
		GeneratedPassword: generatedPassword,
	}

	c.JSON(http.StatusCreated, resp)
}

// Вспомогательная функция для определения, ошибка от RAISERROR или системная
func isSQLError(err error) bool {
	// Можно улучшить, проверяя конкретные коды ошибок SQL Server
	return err != nil
}