CREATE OR ALTER PROCEDURE sp_delete_teacher
    @teacher_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @user_id INT;
    DECLARE @error_message NVARCHAR(4000);
    DECLARE @correlation_id UNIQUEIDENTIFIER = NEWID();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Проверка существования учителя
        SELECT @user_id = user_id
        FROM teachers
        WHERE id = @teacher_id AND deleted_at IS NULL;

        IF @user_id IS NULL
            RAISERROR('Учитель не найден', 16, 1);

        -- Помечаем учителя как удалённого
        UPDATE teachers
        SET deleted_at = SYSDATETIME()
        WHERE id = @teacher_id;

        -- Опционально: деактивируем пользователя
        UPDATE users
        SET is_active = '0', deleted_at = SYSDATETIME()
        WHERE id = @user_id;

        COMMIT TRANSACTION;

        DECLARE @details VARCHAR(255);
        SELECT @details = CONCAT('Учитель ID: ', @teacher_id, ' помечен как удалённый');
        EXEC logging
            @event_type = 'INFO',
            @source = 'sp_delete_teacher',
            @user_id = @user_id,
            @entity_type = 'Teacher',
            @entity_id = @teacher_id,
            @message = 'Учитель удалён (soft-delete)',
            @details = @details,
            @correlation_id = @correlation_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @error_message = ERROR_MESSAGE();

        EXEC logging
            @event_type = 'ERROR',
            @source = 'sp_delete_teacher',
            @user_id = @user_id,
            @message = 'Ошибка в sp_delete_teacher',
            @details = @error_message,
            @correlation_id = @correlation_id;

        RAISERROR(@error_message, 16, 1);
    END CATCH
END;