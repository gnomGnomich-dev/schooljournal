CREATE OR ALTER PROCEDURE add_teacher
    @email VARCHAR(255),             -- email учителя 
    @phone VARCHAR(20),              -- телефон учителя
    @fullname VARCHAR(255),          -- ФИО учителя 
    @subject_name VARCHAR(255),      -- название предмета, например "Математика"
    @education VARCHAR(255) = NULL,  -- образование
    @experience_years INT = NULL,    -- стаж
    @hire_date DATE = NULL,          -- дата приёма на работу
    @gender_name VARCHAR(20) = NULL,  -- пол 
    @generated_password VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @user_id INT;
    DECLARE @teacher_id INT;
    DECLARE @subject_id INT;
    DECLARE @gender_id INT;
    DECLARE @error_message NVARCHAR(4000);
    DECLARE @correlation_id UNIQUEIDENTIFIER = NEWID();
    DECLARE @details VARCHAR(255);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Валидация обязательных параметров 
        IF @email IS NULL OR @phone IS NULL OR @subject_name IS NULL
        BEGIN
            RAISERROR('Email, телефон и название предмета обязательны', 16, 1);
        END

        -- Поиск предмета 
        SELECT @subject_id = id FROM subjects WHERE name = @subject_name;
        IF @subject_id IS NULL
        BEGIN
            RAISERROR('Предмет не найден', 16, 1);
        END

        -- Поиск пола (если указан) 
        IF @gender_name IS NOT NULL
        BEGIN
            SELECT @gender_id = id FROM genders WHERE name = @gender_name;
            IF @gender_id IS NULL
            BEGIN
                RAISERROR('Пол не найден', 16, 1);
            END
        END

        -- Проверка, существует ли уже пользователь с таким email 
        SELECT @user_id = id FROM users WHERE email = @email;
        IF @user_id IS NOT NULL
        BEGIN
            RAISERROR('Пользователь с таким email уже существует', 16, 1);
        END

        -- Создание пользователя (учителя) 
        EXEC sp_create_user_with_password_return
            @email = @email,
            @phone = @phone,
            @role = 2, -- Учитель
            @generated_password = @generated_password OUTPUT,
            @user_id = @user_id OUTPUT;

        -- Создание профиля учителя
        INSERT INTO teachers (user_id, fullname, subject_id, education, experience_years, hire_date)
        VALUES (@user_id, @fullname, @subject_id, @education, @experience_years, @hire_date);
        SET @teacher_id = SCOPE_IDENTITY();

        SELECT @details = CONCAT('Создан учитель: ', @fullname, ' Предмет: ', @subject_name);

        COMMIT TRANSACTION;

        -- Логирование УСПЕХА 
        EXEC dbo.logging 
            @event_type = 'INFO',
            @source = 'DATABASE PROCEDURE',
            @user_id = @user_id,
            @entity_type = 'TEACHER',
            @entity_id = @teacher_id,
            @external_id = NULL,
            @message = 'Учитель успешно создан',
            @details = @details,
            @ip_address = NULL,
            @user_agent = NULL,
            @correlation_id = @correlation_id

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @error_message = ERROR_MESSAGE();

        -- Логирование ОШИБКИ 
        EXEC dbo.logging 
            @event_type = 'ERROR',
            @source = 'DATABASE PROCEDURE',
            @user_id = NULL,
            @entity_type = 'TEACHER',
            @entity_id = NULL,
            @external_id = NULL,
            @message = @error_message,
            @details = 'Ошибка в процедуре add_teacher',
            @ip_address = NULL,
            @user_agent = NULL,
            @correlation_id = @correlation_id

        -- Пробрасываем ошибку
        RAISERROR(@error_message, 16, 1);
    END CATCH
END

DECLARE @pwd VARCHAR(50);
EXEC add_teacher
    @email = '22t118@kuzstu.ru',
    @phone = '89950604780',
    @fullname = 'Хивинцева Арина Мальбертовна',
    @subject_name = 'Математика',
    @generated_password = @pwd OUTPUT;
SELECT @pwd AS generatedpassword;

SELECT * FROM users
SELECT * FROM teachers;
DELETE FROM users
DELETE FROM teachers