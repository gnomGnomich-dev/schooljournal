CREATE OR ALTER PROCEDURE sp_update_semester
    @semester_id INT,
    @name VARCHAR(50) = NULL,
    @start_date DATE = NULL,
    @end_date DATE = NULL,
    @school_id INT = NULL,
    @year DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @error_message NVARCHAR(4000);
    DECLARE @correlation_id UNIQUEIDENTIFIER = NEWID();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Проверка существования
        IF NOT EXISTS (SELECT 1 FROM semesters WHERE id = @semester_id)
            RAISERROR('Семестр не найден', 16, 1);

        -- Проверка школы, если меняется
        IF @school_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM schools WHERE id = @school_id AND deleted_at IS NULL)
            RAISERROR('Школа не найдена', 16, 1);

        -- Проверка пересечения (если меняются даты)
        IF @start_date IS NOT NULL OR @end_date IS NOT NULL
        BEGIN
            DECLARE @new_start DATE = ISNULL(@start_date, (SELECT start_date FROM semesters WHERE id = @semester_id));
            DECLARE @new_end DATE = ISNULL(@end_date, (SELECT end_date FROM semesters WHERE id = @semester_id));

            IF EXISTS (
                SELECT 1 FROM semesters
                WHERE id != @semester_id
                  AND school_id = ISNULL(@school_id, (SELECT school_id FROM semesters WHERE id = @semester_id))
                  AND (
                      (@new_start BETWEEN start_date AND end_date) OR
                      (@new_end BETWEEN start_date AND end_date) OR
                      (start_date BETWEEN @new_start AND @new_end)
                  )
            )
            BEGIN
                RAISERROR('Период пересекается с другим семестром', 16, 1);
            END
        END

        -- Обновляем
        UPDATE semesters
        SET
            name = ISNULL(@name, name),
            start_date = ISNULL(@start_date, start_date),
            end_date = ISNULL(@end_date, end_date),
            school_id = ISNULL(@school_id, school_id),
            year = ISNULL(@year, year)
        WHERE id = @semester_id;

        COMMIT TRANSACTION;

        EXEC logging
            @event_type = 'INFO',
            @source = 'SemesterUpdate',
            @entity_type = 'Semester',
            @entity_id = @semester_id,
            @message = 'Семестр обновлён',
            @details = 'Обновлены данные семестра',
            @correlation_id = @correlation_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @error_message = ERROR_MESSAGE();

        EXEC logging
            @event_type = 'ERROR',
            @source = 'SemesterUpdate',
            @message = 'Ошибка в sp_update_semester',
            @details = @error_message,
            @correlation_id = @correlation_id;

        RAISERROR(@error_message, 16, 1);
    END CATCH
END;