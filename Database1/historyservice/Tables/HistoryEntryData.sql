CREATE TABLE [historyservice].[HistoryEntryData] (
    [Id]            BIGINT         NOT NULL,
    [NewValue]      NVARCHAR (255) NULL,
    [OldValue]      NVARCHAR (255) NULL,
    [PropertyName]  NVARCHAR (255) NULL,
    [PropertyOrder] NVARCHAR (255) NULL,
    [PropertyType]  NVARCHAR (255) NULL,
    [EntryId]       BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_HistoryEntryData_HistoryEntries] FOREIGN KEY ([EntryId]) REFERENCES [historyservice].[HistoryEntries] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [ix_HistoryEntryData_EntryId]
    ON [historyservice].[HistoryEntryData]([EntryId] ASC)
    INCLUDE([NewValue], [OldValue], [PropertyName], [PropertyOrder], [PropertyType]);

