CREATE OR ALTER PROCEDURE sp_create_user_with_password_return
    @email VARCHAR(255),
    @phone VARCHAR(20),
    @role_id INT,
    @is_active CHAR(1) = '1',
    @avatar_url TEXT = NULL,
    @generated_password VARCHAR(50) OUTPUT,
    @user_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Генерируем пароль в "нормальном виде" (plaintext)
        DECLARE @raw_password VARCHAR(50) = LEFT(REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 8);
        SET @generated_password = @raw_password; -- ← Возвращаем клиенту!

        -- 2. Хешируем пароль (SHA2_256 — временное решение, лучше bcrypt на Go)
        DECLARE @password_hash VARCHAR(128) = CONVERT(VARCHAR(128), HASHBYTES('SHA2_256', @raw_password), 2);

        -- 3. Создаем запись в users
        INSERT INTO users (email, password_hash, role_id, phone, is_active, avatar_url, created_at)
        VALUES (@email, @password_hash, @role_id, @phone, @is_active, @avatar_url, SYSDATETIME());

        SET @user_id = SCOPE_IDENTITY();

        -- 4. Логируем создание
        DECLARE @details VARCHAR(255)
        SELECT @details = CONCAT('Email: ', @email, ', Password returned to caller');
        EXEC logging
            @event_type = 'INFO',
            @source = 'UserCreate',
            @user_id = @user_id,
            @entity_type = 'User',
            @message = 'User created with auto-generated password',
            @details = @details

        COMMIT;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        EXEC logging
            @event_type = 'ERROR',
            @source = 'UserCreate',
            @message = 'Failed to create user',
            @details = @ErrorMessage;

        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;

