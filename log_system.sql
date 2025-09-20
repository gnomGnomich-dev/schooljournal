CREATE TABLE system_logs (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    event_time DATETIME2 NOT NULL DEFAULT SYSDATETIME(),     -- Когда произошло событие
    event_type VARCHAR(50) NOT NULL,                         -- Тип события: 'INFO', 'WARN', 'ERROR', 'DEBUG', 'INTEGRATION', 'SECURITY'
    source VARCHAR(100) NULL,                                -- Источник: '1C', 'API', 'Web', 'Scheduler', 'Auth', 'DB'
    user_id INT NULL,                                        -- Кто инициировал (если известен)
    entity_type VARCHAR(100) NULL,                           -- Тип сущности: 'User', 'Teacher', 'Student', 'Grade', 'Schedule'
    entity_id INT NULL,                                      -- ID сущности (если применимо)
    external_id VARCHAR(100) NULL,                           -- Внешний ID (например, из 1С)
    message NVARCHAR(1000) NULL,                             -- Краткое сообщение
    details NVARCHAR(MAX) NULL,                              -- Подробности, JSON, стек ошибки и т.п.
    ip_address VARCHAR(45) NULL,                             -- IP-адрес (если веб)
    user_agent NVARCHAR(500) NULL,                           -- User-Agent браузера/клиента
    correlation_id UNIQUEIDENTIFIER NULL,                    -- Для отслеживания цепочки запросов (например, в микросервисах)
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);

CREATE PROCEDURE logging
    @event_type VARCHAR(50),
    @source VARCHAR(100) = NULL,
    @user_id INT = NULL,
    @entity_type VARCHAR(100) = NULL,
    @entity_id INT = NULL,
    @external_id VARCHAR(100) = NULL,
    @message NVARCHAR(1000) = NULL,
    @details NVARCHAR(MAX) = NULL,
    @ip_address VARCHAR(45) = NULL,
    @user_agent NVARCHAR(500) = NULL,
    @correlation_id UNIQUEIDENTIFIER = NULL
AS
BEGIN
    INSERT INTO system_logs (
        event_type, source, user_id, entity_type, entity_id, external_id,
        message, details, ip_address, user_agent, correlation_id
    )
    VALUES (
        @event_type, @source, @user_id, @entity_type, @entity_id, @external_id,
        @message, @details, @ip_address, @user_agent, @correlation_id
    );
END

-- Индексы для быстрого поиска
CREATE INDEX IX_system_logs_event_time ON system_logs(event_time);
CREATE INDEX IX_system_logs_event_type ON system_logs(event_type);
CREATE INDEX IX_system_logs_user_id ON system_logs(user_id);
CREATE INDEX IX_system_logs_external_id ON system_logs(external_id);
CREATE INDEX IX_system_logs_entity ON system_logs(entity_type, entity_id);
CREATE INDEX IX_system_logs_correlation_id ON system_logs(correlation_id);