CREATE TABLE [dbo].[EventHistory] (
    [EventId]     UNIQUEIDENTIFIER NOT NULL,
    [Name]        NVARCHAR (255)   NULL,
    [Description] NVARCHAR (1024)  NULL,
    [EventType]   NVARCHAR (1024)  NULL,
    [Timestamp]   DATETIME         NULL,
    [ArchiveTime] DATETIME         NULL,
    [Version]     BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([EventId] ASC)
);

