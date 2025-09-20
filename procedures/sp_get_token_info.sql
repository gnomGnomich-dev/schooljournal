CREATE OR ALTER PROCEDURE sp_get_token_info
    @token VARCHAR(255),
    @user_id INT OUTPUT,
    @role INT OUTPUT,                  
    @is_valid BIT OUTPUT,
    @token_status VARCHAR(20) OUTPUT,
    @expires_at DATETIME2 OUTPUT,
    @ip_address VARCHAR(45) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @user_id = at.user_id,
        @role = u.role,                
        @expires_at = at.expires_at,
        @ip_address = at.ip_address,
        @is_valid = CASE
            WHEN at.is_revoked = '0' AND at.expires_at > SYSDATETIME() THEN 1
            ELSE 0
        END,
        @token_status = CASE
            WHEN at.is_revoked = '1' THEN 'revoked'
            WHEN at.expires_at < SYSDATETIME() THEN 'expired'
            ELSE 'active'
        END
    FROM auth_tokens at
    INNER JOIN users u ON at.user_id = u.id  
    WHERE at.token = @token;

    -- Если токен не найден, устанавливаем значения по умолчанию
    IF @user_id IS NULL
    BEGIN
        SET @is_valid = 0;
        SET @token_status = 'not_found';
        SET @role = NULL;
    END
END;