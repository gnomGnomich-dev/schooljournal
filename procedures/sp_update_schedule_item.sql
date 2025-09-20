CREATE OR ALTER PROCEDURE sp_update_schedule_item
    @schedule_id INT,
    @class_id INT = NULL,
    @subject_id INT = NULL,
    @teacher_id INT = NULL,
    @day_id INT = NULL,
    @lesson_number INT = NULL,
    @start_time TIME = NULL,
    @end_time TIME = NULL,
    @room VARCHAR(50) = NULL,
    @homework VARCHAR(MAX) = NULL,
    @semester_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @error_message NVARCHAR(4000);
    DECLARE @correlation_id UNIQUEIDENTIFIER = NEWID();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Проверка существования записи
        IF NOT EXISTS (SELECT 1 FROM schedule WHERE id = @schedule_id)
            RAISERROR('Запись в расписании не найдена', 16, 1);

        -- Проверки на существование сущностей (если переданы)
        IF @class_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM classes WHERE id = @class_id AND deleted_at IS NULL)
            RAISERROR('Класс не найден', 16, 1);
        IF @subject_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM subjects WHERE id = @subject_id)
            RAISERROR('Предмет не найден', 16, 1);
        IF @teacher_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM teachers WHERE id = @teacher_id)
            RAISERROR('Учитель не найден', 16, 1);
        IF @day_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM weekdays WHERE id = @day_id)
            RAISERROR('День недели не найден', 16, 1);
        IF @semester_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM semesters WHERE id = @semester_id)
            RAISERROR('Семестр не найден', 16, 1);

        -- Обновляем запись
        UPDATE schedule
        SET
            class_id = ISNULL(@class_id, class_id),
            subject_id = ISNULL(@subject_id, subject_id),
            teacher_id = ISNULL(@teacher_id, teacher_id),
            day_id = ISNULL(@day_id, day_id),
            lesson_number = ISNULL(@lesson_number, lesson_number),
            start_time = ISNULL(@start_time, start_time),
            end_time = ISNULL(@end_time, end_time),
            room = ISNULL(@room, room),
            homework = ISNULL(@homework, homework),
            semester_id = ISNULL(@semester_id, semester_id)
        WHERE id = @schedule_id;

        COMMIT TRANSACTION;

        EXEC logging
            @event_type = 'INFO',
            @source = 'sp_update_schedule_item',
            @entity_type = 'Schedule',
            @entity_id = @schedule_id,
            @message = 'Запись в расписании обновлена',
            @details = 'Изменены поля расписания',
            @correlation_id = @correlation_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @error_message = ERROR_MESSAGE();

        EXEC logging
            @event_type = 'ERROR',
            @source = 'sp_update_schedule_item',
            @message = 'Ошибка в sp_update_schedule_item',
            @details = @error_message,
            @correlation_id = @correlation_id;

        RAISERROR(@error_message, 16, 1);
    END CATCH
END;