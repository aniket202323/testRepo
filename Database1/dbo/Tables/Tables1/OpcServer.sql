CREATE TABLE [dbo].[OpcServer] (
    [ServerId]      UNIQUEIDENTIFIER NOT NULL,
    [Name]          NVARCHAR (255)   NULL,
    [Description]   NVARCHAR (255)   NULL,
    [HostName]      NVARCHAR (255)   NULL,
    [ProgId]        NVARCHAR (255)   NULL,
    [HealthMonitor] INT              NULL,
    [Version]       BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([ServerId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_OpcServer_Name]
    ON [dbo].[OpcServer]([Name] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_OpcServer_ProgId]
    ON [dbo].[OpcServer]([ProgId] ASC);

