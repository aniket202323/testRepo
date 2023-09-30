CREATE TABLE [WorkOrder].[HoldRecordSegments] (
    [HoldRecordId] BIGINT NOT NULL,
    [SegmentId]    BIGINT NOT NULL,
    CONSTRAINT [PK_HoldRecordSegments] PRIMARY KEY CLUSTERED ([HoldRecordId] ASC, [SegmentId] ASC),
    CONSTRAINT [FK_HoldRecordSegments_HoldRecords_HoldRecordId] FOREIGN KEY ([HoldRecordId]) REFERENCES [WorkOrder].[HoldRecords] ([Id]) ON DELETE CASCADE
);

