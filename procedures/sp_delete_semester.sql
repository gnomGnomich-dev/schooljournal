CREATE OR ALTER PROCEDURE sp_delete_semester
    @semester_id INT
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

        -- Удаляем
        DELETE FROM semesters
        WHERE id = @semester_id;

        COMMIT TRANSACTION;

        EXEC logging
            @event_type = 'INFO',
            @source = 'sp_delete_semester',
            @entity_type = 'Semester',
            @entity_id = @semester_id,
            @message = 'Семестр удалён',
            @details = @semester_id,
            @correlation_id = @correlation_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @error_message = ERROR_MESSAGE();

        EXEC logging
            @event_type = 'ERROR',
            @source = 'sp_delete_semester',
            @message = 'Ошибка в sp_delete_semester',
            @details = @error_message,
            @correlation_id = @correlation_id;

        RAISERROR(@error_message, 16, 1);
    END CATCH
END;