CREATE OR ALTER PROCEDURE sp_delete_schedule_item
    @schedule_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @class_id INT;
    DECLARE @subject_id INT;
    DECLARE @teacher_id INT;
    DECLARE @day_id INT;
    DECLARE @lesson_number INT;
    DECLARE @semester_id INT;
    DECLARE @error_message NVARCHAR(4000);
    DECLARE @correlation_id UNIQUEIDENTIFIER = NEWID();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Проверяем, существует ли запись
        SELECT
            @class_id = class_id,
            @subject_id = subject_id,
            @teacher_id = teacher_id,
            @day_id = day_id,
            @lesson_number = lesson_number,
            @semester_id = semester_id
        FROM schedule
        WHERE id = @schedule_id;

        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR('Запись в расписании не найдена', 16, 1);
        END

        -- Физически удаляем запись
        DELETE FROM schedule
        WHERE id = @schedule_id;

        COMMIT TRANSACTION;

        DECLARE @details VARCHAR(255);
        SELECT @details = CONCAT(
                'Удалена запись: класс ', @class_id,
                ', предмет ', @subject_id,
                ', день ', @day_id,
                ', урок ', @lesson_number,
                ', семестр ', @semester_id);
        -- Логируем успешное удаление
        EXEC logging
            @event_type = 'INFO',
            @source = 'sp_delete_schedule_item',
            @entity_type = 'Schedule',
            @entity_id = @schedule_id,
            @message = 'Запись расписания удалена',
            @details = @details,
            @correlation_id = @correlation_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @error_message = ERROR_MESSAGE();

        EXEC logging
            @event_type = 'ERROR',
            @source = 'sp_delete_schedule_item',
            @message = 'Ошибка при удалении записи расписания',
            @details = @error_message,
            @correlation_id = @correlation_id;

        RAISERROR(@error_message, 16, 1);
    END CATCH
END;