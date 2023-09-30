CREATE TABLE [WorkOrder].[CompleteQuantityRecords] (
    [Id]                    BIGINT             NOT NULL,
    [SegmentActualId]       BIGINT             NOT NULL,
    [QuantityCompletedBy]   NVARCHAR (MAX)     NULL,
    [Quantity]              INT                NOT NULL,
    [QuantityCompletedTime] DATETIMEOFFSET (7) NOT NULL,
    CONSTRAINT [PK_CompleteQuantityRecords] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_CompleteQuantityRecords_SegmentActuals_SegmentActualId] FOREIGN KEY ([SegmentActualId]) REFERENCES [WorkOrder].[SegmentActuals] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_CompleteQuantityRecords_SegmentActualId]
    ON [WorkOrder].[CompleteQuantityRecords]([SegmentActualId] ASC);

