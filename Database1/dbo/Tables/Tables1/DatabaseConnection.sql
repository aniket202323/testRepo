CREATE TABLE [dbo].[DatabaseConnection] (
    [DatabaseConnectionId] UNIQUEIDENTIFIER NOT NULL,
    [Name]                 NVARCHAR (50)    NULL,
    [Description]          NVARCHAR (255)   NULL,
    [ConnectionString]     NVARCHAR (255)   NULL,
    [Server]               NVARCHAR (255)   NULL,
    [Dsn]                  NVARCHAR (255)   NULL,
    [Port]                 INT              NULL,
    [Timeout]              INT              NULL,
    [r_Database]           NVARCHAR (255)   NULL,
    [Provider]             NVARCHAR (255)   NULL,
    [Username]             NVARCHAR (255)   NULL,
    [EncryptedPassword]    NVARCHAR (255)   NULL,
    [DatabaseDriver]       NVARCHAR (255)   NULL,
    [Version]              BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([DatabaseConnectionId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_DatabaseConnection_Name]
    ON [dbo].[DatabaseConnection]([Name] ASC);

