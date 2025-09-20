CREATE OR ALTER PROCEDURE add_student
    @email VARCHAR(255),           -- email ученика
    @fullname VARCHAR(MAX),        -- ФИО ученика
    @phone VARCHAR(20),            -- телефон ученика
    @birth_date DATE,              -- дата рождения ученика
    @gender_name VARCHAR(20),      -- пол ученика: 'Мужской', 'Женский'
    @class_name VARCHAR(10),       -- название класса: '10А'
    @parent_fullname VARCHAR(255), -- ФИО родителя
    @parent_email VARCHAR(255),    -- email родителя (для создания аккаунта)
    @parent_phone VARCHAR(20),     -- телефон родителя
    @parent_passport VARCHAR(50) , -- паспорт родителя
    @parent_birth_date DATE ,      -- дата рождения родителя
    @parent_gender_name VARCHAR(20),  -- пол родителя
    @student_password VARCHAR(50) OUTPUT,   -- Пароль ученика
    @parent_password VARCHAR(50) OUTPUT     -- Пароль родителя
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @user_id INT;
    DECLARE @student_user_id INT;
    DECLARE @parent_user_id INT;
    DECLARE @parent_id INT;
    DECLARE @class_id INT;
    DECLARE @student_gender_id INT;
    DECLARE @parent_gender_id INT;
    DECLARE @error_message NVARCHAR(4000);
    DECLARE @correlation_id UNIQUEIDENTIFIER = NEWID();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Валидация обязательных параметров 
        IF @email IS NULL OR @phone IS NULL OR @birth_date IS NULL OR @gender_name IS NULL OR 
           @class_name IS NULL OR @parent_fullname IS NULL OR @parent_email IS NULL OR @parent_phone IS NULL
           OR @parent_birth_date IS NULL OR @parent_gender_name IS NULL OR @parent_passport IS NULL
        BEGIN
            RAISERROR('Все основные параметры обязательны для заполнения', 16, 1);
        END

        -- Поиск класса 
        SELECT @class_id = id FROM classes WHERE name = @class_name AND deleted_at IS NULL;
        IF @class_id IS NULL
        BEGIN
            RAISERROR('Класс не найден или удалён', 16, 1);
        END

        -- Поиск пола ученика ===
        SELECT @student_gender_id = id FROM genders WHERE name = @gender_name;
        IF @student_gender_id IS NULL
        BEGIN
            RAISERROR('Пол ученика не найден', 16, 1);
        END

        -- Поиск пола родителя
        IF @parent_gender_name IS NOT NULL
        BEGIN
            SELECT @parent_gender_id = id FROM genders WHERE name = @parent_gender_name;
            IF @parent_gender_id IS NULL
            BEGIN
                RAISERROR('Пол родителя не найден', 16, 1);
            END
        END

        -- Создание пользователя-родителя
        SELECT @parent_user_id = id FROM users WHERE email = @parent_email;
        
        IF @parent_user_id IS NULL
        BEGIN
            -- Создаем пользователя-родителя через процедуру
            EXEC sp_create_user_with_password_return
                @email = @parent_email,
                @phone = @parent_phone,
                @role = 3, -- Родитель
                @generated_password = @parent_password OUTPUT,
                @user_id = @user_id;

            -- Создаем профиль родителя
            INSERT INTO parents (fullname, user_id, birth_date, gender_id, passport, phone)
            VALUES (@parent_fullname, @user_id, @parent_birth_date, @parent_gender_id, @parent_passport, @parent_phone);
            SET @parent_id = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            -- Если родитель уже существует — не генерируем пароль
            SET @parent_password = NULL;
            SELECT @parent_id = id FROM parents WHERE user_id = @parent_user_id;
        END

        -- Создание пользователя-ученика 
        EXEC sp_create_user_with_password_return
            @email = @email,
            @phone = @phone,
            @role = 1, -- Ученик
            @generated_password = @student_password OUTPUT,
            @user_id = @user_id;

        -- Создание ученика 
        INSERT INTO students (user_id, fullname, class_id, birth_date, gender_id, enrollment_date, parent_id)
        VALUES (@user_id, @fullname, @class_id, @birth_date, @student_gender_id, SYSDATETIME(), @parent_id);

        COMMIT TRANSACTION;

        -- === 9. Логирование УСПЕХА ===
        EXEC dbo.logging 
            @event_type = 'INFO',
            @source = 'DATABASE PROCEDURE',
            @user_id = @student_user_id,
            @entity_type = 'STUDENT',
            @entity_id = @student_user_id,
            @external_id = NULL,
            @message = 'Ученик и родитель успешно созданы',
            @details = 'Вызвана процедура add_student',
            @ip_address = NULL,
            @user_agent = NULL,
            @correlation_id = @correlation_id,
            @status_code = 200;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @error_message = ERROR_MESSAGE();

        -- === Логирование ОШИБКИ ===
        EXEC dbo.logging 
            @event_type = 'ERROR',
            @source = 'DATABASE PROCEDURE',
            @user_id = NULL,
            @entity_type = 'STUDENT',
            @entity_id = NULL,
            @external_id = NULL,
            @message = @error_message,
            @details = 'Ошибка в процедуре add_student',
            @ip_address = NULL,
            @user_agent = NULL,
            @correlation_id = @correlation_id,
            @status_code = 500;

        -- Пробрасываем ошибку
        RAISERROR(@error_message, 16, 1);
    END CATCH
END