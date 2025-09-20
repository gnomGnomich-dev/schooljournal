CREATE OR ALTER PROCEDURE sp_update_student
    @student_id INT,
    @fullname VARCHAR(MAX) = NULL,
    @birth_date DATE = NULL,
    @gender_name VARCHAR(20) = NULL,
    @class_name VARCHAR(10) = NULL,
    @parent_fullname VARCHAR(255) = NULL,
    @parent_email VARCHAR(255) = NULL,
    @parent_phone VARCHAR(20) = NULL,
    @parent_passport VARCHAR(50) = NULL,
    @parent_birth_date DATE = NULL,
    @parent_gender_name VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @user_id INT;
    DECLARE @class_id INT;
    DECLARE @student_gender_id INT;
    DECLARE @parent_gender_id INT;
    DECLARE @parent_user_id INT;
    DECLARE @parent_id INT;
    DECLARE @error_message NVARCHAR(4000);
    DECLARE @correlation_id UNIQUEIDENTIFIER = NEWID();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Проверка существования ученика
        SELECT @user_id = user_id FROM students WHERE id = @student_id AND deleted_at IS NULL;
        IF @user_id IS NULL
            RAISERROR('Ученик не найден', 16, 1);

        -- Обновление пола ученика
        IF @gender_name IS NOT NULL
        BEGIN
            SELECT @student_gender_id = id FROM genders WHERE name = @gender_name;
            IF @student_gender_id IS NULL
                RAISERROR('Пол ученика не найден', 16, 1);
        END

        -- Обновление класса
        IF @class_name IS NOT NULL
        BEGIN
            SELECT @class_id = id FROM classes WHERE name = @class_name AND deleted_at IS NULL;
            IF @class_id IS NULL
                RAISERROR('Класс не найден или удалён', 16, 1);
        END

        -- Если обновляются данные родителя
        IF @parent_fullname IS NOT NULL OR @parent_email IS NOT NULL OR @parent_phone IS NOT NULL OR
           @parent_passport IS NOT NULL OR @parent_birth_date IS NOT NULL OR @parent_gender_name IS NOT NULL
        BEGIN
            -- Получаем текущего родителя ученика
            SELECT @parent_id = parent_id FROM students WHERE id = @student_id;
            IF @parent_id IS NULL
                RAISERROR('Родитель не привязан к ученику', 16, 1);

            -- Получаем user_id родителя
            SELECT @parent_user_id = user_id FROM parents WHERE id = @parent_id;

            -- Обновляем пользователя родителя (если email/phone переданы)
            IF @parent_email IS NOT NULL OR @parent_phone IS NOT NULL
            BEGIN
                UPDATE users
                SET
                    email = ISNULL(@parent_email, email),
                    phone = ISNULL(@parent_phone, phone),
                    updated_at = SYSDATETIME()
                WHERE id = @parent_user_id;
            END

            -- Обновляем пол родителя
            IF @parent_gender_name IS NOT NULL
            BEGIN
                SELECT @parent_gender_id = id FROM genders WHERE name = @parent_gender_name;
                IF @parent_gender_id IS NULL
                    RAISERROR('Пол родителя не найден', 16, 1);
            END

            -- Обновляем профиль родителя
            UPDATE parents
            SET
                fullname = ISNULL(@parent_fullname, fullname),
                birth_date = ISNULL(@parent_birth_date, birth_date),
                gender_id = ISNULL(@parent_gender_id, gender_id),
                passport = ISNULL(@parent_passport, passport),
                phone = ISNULL(@parent_phone, phone),
                updated_at = SYSDATETIME()
            WHERE id = @parent_id;
        END

        -- Обновляем профиль ученика
        UPDATE students
        SET
            fullname = ISNULL(@fullname, fullname),
            birth_date = ISNULL(@birth_date, birth_date),
            gender_id = ISNULL(@student_gender_id, gender_id),
            class_id = ISNULL(@class_id, class_id),
            updated_at = SYSDATETIME()
        WHERE id = @student_id;

        COMMIT TRANSACTION;

        DECLARE @details VARCHAR(255);
        SELECT @details = CONCAT('Обновлены данные ученика ID: ', @student_id);
        EXEC logging
            @event_type = 'INFO',
            @source = 'StudentUpdate',
            @user_id = @user_id,
            @entity_type = 'Student',
            @entity_id = @student_id,
            @message = 'Профиль ученика обновлён',
            @details = @details,
            @correlation_id = @correlation_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @error_message = ERROR_MESSAGE();

        EXEC logging
            @event_type = 'ERROR',
            @source = 'StudentUpdate',
            @user_id = @user_id,
            @message = 'Ошибка в sp_update_student',
            @details = @error_message,
            @correlation_id = @correlation_id;

        RAISERROR(@error_message, 16, 1);
    END CATCH
END;