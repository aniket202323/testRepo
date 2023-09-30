CREATE TABLE [dbo].[Historian_Collector] (
    [Id]          UNIQUEIDENTIFIER NOT NULL,
    [Name]        NVARCHAR (1024)  NOT NULL,
    [Type]        INT              NULL,
    [Version]     BIGINT           NULL,
    [HistorianId] UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [Historian_Collector_Historian_Server_Relation1] FOREIGN KEY ([HistorianId]) REFERENCES [dbo].[Historian_Server] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [IX_Historian_Collector_Name]
    ON [dbo].[Historian_Collector]([Name] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Historian_Collector_HistorianId]
    ON [dbo].[Historian_Collector]([HistorianId] ASC);

