CREATE TABLE [historyservice].[HistoryEntries] (
    [Id]                  BIGINT         NOT NULL,
    [EntryType]           NVARCHAR (255) NULL,
    [EventDate]           DATETIME2 (7)  NULL,
    [MaterialLotActualId] BIGINT         NULL,
    [PerformedBy]         NVARCHAR (255) NULL,
    [SegmentActualId]     BIGINT         NULL,
    [WorkOrderId]         BIGINT         NULL,
    [SourceEventId]       BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_HistoryEntries_SourceEvents] FOREIGN KEY ([SourceEventId]) REFERENCES [historyservice].[SourceEvents] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [Ix_Vwistory_Events_WrkOrd_EntryType]
    ON [historyservice].[HistoryEntries]([WorkOrderId] ASC, [EntryType] ASC)
    INCLUDE([Id], [EventDate], [MaterialLotActualId], [PerformedBy], [SegmentActualId], [SourceEventId]);

