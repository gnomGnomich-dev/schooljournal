CREATE OR ALTER PROCEDURE sp_update_teacher
    @teacher_id INT,
    @fullname VARCHAR(255) = NULL,
    @subject_name VARCHAR(255) = NULL,
    @education VARCHAR(255) = NULL,
    @experience_years INT = NULL,
    @hire_date DATE = NULL,
    @gender_name VARCHAR(20) = NULL,
    @email VARCHAR(255) = NULL,
    @phone VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @user_id INT;
    DECLARE @subject_id INT;
    DECLARE @gender_id INT;
    DECLARE @error_message NVARCHAR(4000);
    DECLARE @correlation_id UNIQUEIDENTIFIER = NEWID();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Проверка существования учителя
        SELECT @user_id = user_id FROM teachers WHERE id = @teacher_id AND deleted_at IS NULL;
        IF @user_id IS NULL
            RAISERROR('Учитель не найден', 16, 1);

        -- Обновление предмета
        IF @subject_name IS NOT NULL
        BEGIN
            SELECT @subject_id = id FROM subjects WHERE name = @subject_name;
            IF @subject_id IS NULL
                RAISERROR('Предмет не найден', 16, 1);
        END

        -- Обновление пола
        IF @gender_name IS NOT NULL
        BEGIN
            SELECT @gender_id = id FROM genders WHERE name = @gender_name;
            IF @gender_id IS NULL
                RAISERROR('Пол не найден', 16, 1);
        END

        -- Обновление пользователя (email, phone)
        IF @email IS NOT NULL OR @phone IS NOT NULL
        BEGIN
            UPDATE users
            SET
                email = ISNULL(@email, email),
                phone = ISNULL(@phone, phone),
                updated_at = SYSDATETIME()
            WHERE id = @user_id;
        END

        -- Обновление профиля учителя
        UPDATE teachers
        SET
            fullname = ISNULL(@fullname, fullname),
            subject_id = ISNULL(@subject_id, subject_id),
            education = ISNULL(@education, education),
            experience_years = ISNULL(@experience_years, experience_years),
            hire_date = ISNULL(@hire_date, hire_date),
            gender_id = ISNULL(@gender_id, gender_id),
            updated_at = SYSDATETIME()
        WHERE id = @teacher_id;

        COMMIT TRANSACTION;

        DECLARE @details VARCHAR(255);
        SELECT @details = CONCAT('Обновлены данные учителя ID: ', @teacher_id);
        EXEC logging
            @event_type = 'INFO',
            @source = 'sp_update_teacher',
            @user_id = @user_id,
            @entity_type = 'Teacher',
            @entity_id = @teacher_id,
            @message = 'Профиль учителя обновлён',
            @details = @details,
            @correlation_id = @correlation_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @error_message = ERROR_MESSAGE();

        EXEC logging
            @event_type = 'ERROR',
            @source = 'sp_update_teacher',
            @user_id = @user_id,
            @message = 'Ошибка в sp_update_teacher',
            @details = @error_message,
            @correlation_id = @correlation_id;

        RAISERROR(@error_message, 16, 1);
    END CATCH
END;