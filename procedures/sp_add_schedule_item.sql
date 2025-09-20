CREATE OR ALTER PROCEDURE sp_add_schedule_item
    @class_id INT,
    @subject_id INT,
    @teacher_id INT,
    @day_id INT,
    @lesson_number INT,
    @start_time TIME,
    @end_time TIME,
    @room VARCHAR(50),
    @semester_id INT,
    @schedule_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @error_message NVARCHAR(4000);
    DECLARE @correlation_id UNIQUEIDENTIFIER = NEWID();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Проверки существования сущностей
        IF NOT EXISTS (SELECT 1 FROM classes WHERE id = @class_id AND deleted_at IS NULL)
            RAISERROR('Класс не найден', 16, 1);
        IF NOT EXISTS (SELECT 1 FROM subjects WHERE id = @subject_id)
            RAISERROR('Предмет не найден', 16, 1);
        IF NOT EXISTS (SELECT 1 FROM teachers WHERE id = @teacher_id)
            RAISERROR('Учитель не найден', 16, 1);
        IF NOT EXISTS (SELECT 1 FROM weekdays WHERE id = @day_id)
            RAISERROR('День недели не найден', 16, 1);
        IF NOT EXISTS (SELECT 1 FROM semesters WHERE id = @semester_id)
            RAISERROR('Четверть не найдена', 16, 1);

        -- Проверка на конфликт (если нужно — можно расширить)
        IF EXISTS (
            SELECT 1 FROM schedule
            WHERE class_id = @class_id
              AND day_id = @day_id
              AND lesson_number = @lesson_number
              AND semester_id = @semester_id
              AND is_active = '1'
        )
        BEGIN
            RAISERROR('В это время у класса уже есть предмет', 16, 1);
        END

        -- Добавляем запись
        INSERT INTO schedule (
            class_id, subject_id, teacher_id, day_id, lesson_number,
            start_time, end_time, room, semester_id
        )
        VALUES (
            @class_id, @subject_id, @teacher_id, @day_id, @lesson_number,
            @start_time, @end_time, @room, @semester_id
        );

        SET @schedule_id = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        DECLARE @details VARCHAR(255);
        SELECT @details = CONCAT('Класс: ', @class_id, ', Предмет: ', @subject_id, ', Урок: ', @lesson_number);
        EXEC logging
            @event_type = 'INFO',
            @source = 'sp_add_schedule_item',
            @entity_type = 'Schedule',
            @entity_id = @schedule_id,
            @message = 'Запись в расписание добавлена',
            @details = @details,
            @correlation_id = @correlation_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @error_message = ERROR_MESSAGE();

        EXEC logging
            @event_type = 'ERROR',
            @source = 'sp_add_schedule_item',
            @message = 'Ошибка в sp_add_schedule_item',
            @details = @error_message,
            @correlation_id = @correlation_id;

        RAISERROR(@error_message, 16, 1);
    END CATCH
END;