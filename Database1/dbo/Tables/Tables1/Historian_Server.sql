CREATE TABLE [dbo].[Historian_Server] (
    [Id]          UNIQUEIDENTIFIER NOT NULL,
    [Name]        NVARCHAR (255)   NOT NULL,
    [Address]     NVARCHAR (255)   NULL,
    [Description] NVARCHAR (255)   NULL,
    [Username]    NVARCHAR (255)   NULL,
    [Password]    NVARCHAR (255)   NULL,
    [Domain]      NVARCHAR (255)   NULL,
    [Disabled]    BIT              NULL,
    [Version]     BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Historian_Server_Name]
    ON [dbo].[Historian_Server]([Name] ASC);

