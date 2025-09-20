CREATE OR ALTER PROCEDURE sp_add_semester
    @name VARCHAR(50),           
    @start_date DATE,
    @end_date DATE,
    @school_id INT,
    @year DATE,               
    @semester_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @error_message NVARCHAR(4000);
    DECLARE @correlation_id UNIQUEIDENTIFIER = NEWID();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Проверка школы
        IF NOT EXISTS (SELECT 1 FROM schools WHERE id = @school_id AND deleted_at IS NULL)
            RAISERROR('Школа не найдена', 16, 1);

        -- Проверка пересечения дат (опционально)
        IF EXISTS (
            SELECT 1 FROM semesters
            WHERE school_id = @school_id
              AND (
                  (@start_date BETWEEN start_date AND end_date) OR
                  (@end_date BETWEEN start_date AND end_date) OR
                  (start_date BETWEEN @start_date AND @end_date)
              )
        )
        BEGIN
            RAISERROR('Период пересекается с существующим семестром', 16, 1);
        END

        -- Добавляем семестр
        INSERT INTO semesters (name, start_date, end_date, school_id, year)
        VALUES (@name, @start_date, @end_date, @school_id, @year);

        SET @semester_id = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        DECLARE @details VARCHAR(255);
        SELECT @details = CONCAT('Название: ', @name, ', Период: ', @start_date, ' - ', @end_date);
        EXEC logging
            @event_type = 'INFO',
            @source = 'sp_add_semester',
            @entity_type = 'Semester',
            @entity_id = @semester_id,
            @message = 'Семестр добавлен',
            @details = @details,
            @correlation_id = @correlation_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @error_message = ERROR_MESSAGE();

        EXEC logging
            @event_type = 'ERROR',
            @source = 'sp_add_semester',
            @message = 'Ошибка в sp_add_semester',
            @details = @error_message,
            @correlation_id = @correlation_id;

        RAISERROR(@error_message, 16, 1);
    END CATCH
END;