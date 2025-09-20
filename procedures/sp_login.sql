CREATE OR ALTER PROCEDURE sp_login
	@email VARCHAR(255),
	@password VARCHAR(255),
    @user_agent NVARCHAR(500) = NULL,
    @ip_address VARCHAR(45) = NULL,
	@token VARCHAR(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @user_id INT, @stored_hash VARCHAR(255), @is_active CHAR(1), @role INT;

	BEGIN TRY
		BEGIN TRANSACTION

		SELECT
			@user_id = id,
			@stored_hash = password_hash,
			@is_active = is_active,
			@role = role
		FROM users
		WHERE email = @email
			AND deleted_at IS NULL;

		IF @user_id IS NULL
		BEGIN
			EXEC logging 
                @event_type = 'WARN',
                @source = 'DB_LOGIN',
                @message = 'Login failed: user not found',
                @details = @email,
                @ip_address = @ip_address;

            RAISERROR('Invalid email or password', 16, 1);
            RETURN;
        END;

		IF @is_active != '1'
		BEGIN
			EXEC logging 
                @event_type = 'WARN',
                @source = 'DB_LOGIN',
                @user_id = @user_id,
                @message = 'Login failed: account inactive',
                @ip_address = @ip_address;

            RAISERROR('Account is disabled', 16, 1);
            RETURN;
        END;

		IF @stored_hash != CONVERT(VARCHAR(128), HASHBYTES('SHA2_256', @password), 2)
		BEGIN
            EXEC logging 
                @event_type = 'WARN',
                @source = 'DB_LOGIN',
                @user_id = @user_id,
                @message = 'Login failed: invalid password',
                @ip_address = @ip_address;

            RAISERROR('Invalid email or password', 16, 1);
            RETURN;
        END;

        DECLARE @raw_token UNIQUEIDENTIFIER = NEWID();
        SET @token = REPLACE(CAST(@raw_token AS VARCHAR(36)), '-', '');

        UPDATE auth_tokens
        SET is_revoked = '1'
        WHERE user_id = @user_id
            AND is_revoked = '0'
            AND expires_at > SYSDATETIME();
        
        INSERT INTO auth_tokens (user_id, token, ip_address, user_agent, expires_at)
        VALUES (
            @user_id,
            @token,
            @ip_address,
            @user_agent,
            DATEADD(HOUR, 24, SYSDATETIME())
        );

        EXEC logging 
            @event_type = 'INFO',
            @source = 'DB_LOGIN',
            @user_id = @user_id,
            @message = 'Login successful',
            @ip_address = @ip_address;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        EXEC logging 
            @event_type = 'ERROR',
            @source = 'DB_LOGIN',
            @message = 'Login procedure failed',
            @details = @ErrorMessage;

        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;