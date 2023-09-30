CREATE TABLE [dbo].[Historian_Tag] (
    [Id]          UNIQUEIDENTIFIER NOT NULL,
    [Name]        NVARCHAR (400)   NOT NULL,
    [DataType]    INT              NULL,
    [Description] NVARCHAR (255)   NULL,
    [Orphan]      BIT              NULL,
    [Version]     BIGINT           NULL,
    [HistorianId] UNIQUEIDENTIFIER NULL,
    [CollectorId] UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [Historian_Tag_Historian_Collector_Relation1] FOREIGN KEY ([CollectorId]) REFERENCES [dbo].[Historian_Collector] ([Id]),
    CONSTRAINT [Historian_Tag_Historian_Server_Relation1] FOREIGN KEY ([HistorianId]) REFERENCES [dbo].[Historian_Server] ([Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Historian_Tag_HistorianId_Name]
    ON [dbo].[Historian_Tag]([HistorianId] ASC, [Name] ASC)
    INCLUDE([CollectorId], [Description], [DataType], [Orphan], [Version]);


GO
CREATE NONCLUSTERED INDEX [NC_Historian_Tag_CollectorId]
    ON [dbo].[Historian_Tag]([CollectorId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX1_Historian_Tag]
    ON [dbo].[Historian_Tag]([HistorianId] ASC, [CollectorId] ASC, [Name] ASC)
    INCLUDE([Orphan]);


GO
CREATE NONCLUSTERED INDEX [IX2_Historian_Tag_Orphan]
    ON [dbo].[Historian_Tag]([Orphan] ASC, [HistorianId] ASC)
    INCLUDE([Id]);

