CREATE TABLE [historyservice].[SourceEvents] (
    [Id]                 BIGINT         IDENTITY (1, 1) NOT NULL,
    [EventAggregateType] NVARCHAR (255) NULL,
    [EventDate]          NVARCHAR (30)  NULL,
    [EventType]          NVARCHAR (255) NULL,
    [MessageId]          NVARCHAR (40)  NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

