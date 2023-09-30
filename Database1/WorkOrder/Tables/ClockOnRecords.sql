CREATE TABLE [WorkOrder].[ClockOnRecords] (
    [Id]              BIGINT             NOT NULL,
    [SegmentActualId] BIGINT             NOT NULL,
    [Operator]        NVARCHAR (100)     NOT NULL,
    [ClockOnTime]     DATETIMEOFFSET (7) NOT NULL,
    [ClockOffTime]    DATETIMEOFFSET (7) NULL,
    [ClockOffBy]      NVARCHAR (MAX)     NULL,
    [ClockOnBy]       NVARCHAR (MAX)     NULL,
    [LaborTypeId]     BIGINT             NULL,
    CONSTRAINT [PK_ClockOnRecords] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ClockOnRecords_SegmentActuals_SegmentActualId] FOREIGN KEY ([SegmentActualId]) REFERENCES [WorkOrder].[SegmentActuals] ([Id]) ON DELETE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_ClockOnRecords_SegmentActualId_Operator]
    ON [WorkOrder].[ClockOnRecords]([SegmentActualId] ASC, [Operator] ASC) WHERE ([ClockOffTime] IS NULL);


GO
CREATE NONCLUSTERED INDEX [IX_ClockOnRecords_SegmentActualId]
    ON [WorkOrder].[ClockOnRecords]([SegmentActualId] ASC)
    INCLUDE([Id], [Operator], [ClockOnTime], [ClockOffTime], [ClockOffBy], [ClockOnBy], [LaborTypeId]);

