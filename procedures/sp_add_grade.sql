CREATE OR ALTER PROCEDURE sp_add_grade
	@student_id INT,
	@subject_id INT,
	@teacher_id INT,
	@grade_value_name VARCHAR(3),
	@comment VARCHAR(255) = NULL,
	@grade_id INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @value_id INT;
	DECLARE @error_message NVARCHAR(4000);
	DECLARE @correlation_id UNIQUEIDENTIFIER = NEWID();

	BEGIN TRY
		BEGIN TRANSACTION;

		IF NOT EXISTS (SELECT 1 
						FROM students s 
						INNER JOIN users u 
							ON s.user_id = u.id 
						WHERE 
							s.id = @student_id 
								AND u.deleted_at IS NULL)
			RAISERROR('Ученик не найден', 16, 1);

		IF NOT EXISTS (SELECT 1 FROM subjects WHERE id = @subject_id)
			RAISERROR('Предмет не существует', 16, 1);

		IF NOT EXISTS (SELECT 1 
						FROM teachers t 
						INNER JOIN users u 
							ON t.user_id = u.id 
						WHERE 
							t.id = @teacher_id 
								AND u.deleted_at IS NULL)
			RAISERROR('Учитель не найден', 16, 1);

		SELECT @value_id = id FROM grade_values WHERE name = @grade_value_name;
		IF @value_id IS NULL
			RAISERROR('Некорректное значение отметки', 16, 1);

		INSERT INTO grades (student_id, subject_id, teacher_id, value_id, comment)
		VALUES (@student_id, @subject_id, @teacher_id, @value_id, @comment);

		SET @grade_id = SCOPE_IDENTITY();

		COMMIT TRANSACTION;

		DECLARE @details VARCHAR(255);
		SELECT @details = CONCAT('Студент: ', @student_id, ', Предмет: ', @subject_id, ', Значение: ', @grade_value_name);
		EXEC logging
			@event_type = 'INFO',
			@source = 'sp_add_grade',
			@user_id = @teacher_id,
			@entity_type = 'Grade',
			@entity_id = @grade_id,
			@message = 'Отметка добавлена',
			@details = @details,
			@correlation_id = @correlation_id;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 1 ROLLBACK TRANSACTION;

		SET @error_message = ERROR_MESSAGE();

		EXEC logging
            @event_type = 'ERROR',
            @source = 'sp_add_grade',
            @user_id = @teacher_id,
            @message = 'Ошибка в sp_add_grade',
            @details = @error_message,
            @correlation_id = @correlation_id;

        RAISERROR(@error_message, 16, 1);
    END CATCH
END;
