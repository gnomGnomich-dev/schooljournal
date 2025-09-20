CREATE OR ALTER PROCEDURE sp_update_grade
	@grade_id INT,
	@grade_value_name VARCHAR(3) = NULL,
	@comment VARCHAR(255) = NULL,
	@date DATE = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @value_id INT;
	DECLARE @teacher_id INT;
	DECLARE @error_message NVARCHAR(4000);
	DECLARE @correlation_id UNIQUEIDENTIFIER = NEWID();

	BEGIN TRY
		BEGIN TRANSACTION

		IF NOT EXISTS (SELECT 1 FROM grades WHERE id = @grade_id AND deleted_at IS NULL)
			RAISERROR('Оценка не найдена', 16, 1);

		SELECT @teacher_id = teacher_id FROM grades WHERE id = @grade_id;

		IF @grade_value_name IS NOT NULL
		BEGIN
			SELECT @value_id = id FROM grade_values WHERE name = @grade_value_name;
			IF @value_id IS NULL
				RAISERROR('Некорректное значение оценки или посещаемости', 16, 1);
		END;

		UPDATE grades
		SET
			value_id = ISNULL(@value_id, value_id),
			comment = ISNULL(@comment, comment)
		WHERE id = @grade_id;

		COMMIT TRANSACTION;

		DECLARE @details VARCHAR(255);
		SELECT @details = CONCAT('Новое значение: ', ISNULL(@grade_value_name, 'не изменено'));
		EXEC logging
			@event_type = 'INFO',
            @source = 'sp_update_grade',
            @user_id = @teacher_id,
            @entity_type = 'Grade',
            @entity_id = @grade_id,
            @message = 'Оценка или посещаемость обновлена',
            @details = @details,
            @correlation_id = @correlation_id;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

		SET @error_message = ERROR_MESSAGE();

		EXEC logging
			@event_type = 'ERROR',
            @source = 'sp_update_grade',
            @user_id = @teacher_id,
            @message = 'Ошибка в sp_update_grade',
            @details = @error_message,
            @correlation_id = @correlation_id;

        RAISERROR(@error_message, 16, 1);
    END CATCH
END