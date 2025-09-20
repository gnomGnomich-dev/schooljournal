CREATE OR ALTER PROCEDURE sp_delete_student
    @student_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @user_id INT;
    DECLARE @parent_id INT;
    DECLARE @error_message NVARCHAR(4000);
    DECLARE @correlation_id UNIQUEIDENTIFIER = NEWID();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Проверка существования ученика
        SELECT @user_id = user_id, @parent_id = parent_id
        FROM students
        WHERE id = @student_id AND deleted_at IS NULL;

        IF @user_id IS NULL
            RAISERROR('Ученик не найден', 16, 1);

        -- Помечаем ученика как удалённого
        UPDATE students
        SET deleted_at = SYSDATETIME()
        WHERE id = @student_id;

        -- Опционально: помечаем и пользователя как неактивного
        UPDATE users
        SET is_active = '0', deleted_at = SYSDATETIME()
        WHERE id = @user_id;

        -- Жестко удаляем родителя
        DELETE FROM parents
        WHERE id = (SELECT parent_id 
                    FROM students 
                    WHERE id = @student_id);

        COMMIT TRANSACTION;

        DECLARE @details VARCHAR(255);
        SELECT @details = CONCAT('Ученик ID: ', @student_id, ' помечен как удалённый')
        EXEC logging
            @event_type = 'INFO',
            @source = 'sp_delete_student',
            @user_id = @user_id,
            @entity_type = 'Student',
            @entity_id = @student_id,
            @message = 'Ученик удалён (soft-delete)',
            @details = @details,
            @correlation_id = @correlation_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @error_message = ERROR_MESSAGE();

        EXEC logging
            @event_type = 'ERROR',
            @source = 'sp_delete_student',
            @user_id = @user_id,
            @message = 'Ошибка в sp_delete_student',
            @details = @error_message,
            @correlation_id = @correlation_id;

        RAISERROR(@error_message, 16, 1);
    END CATCH
END;