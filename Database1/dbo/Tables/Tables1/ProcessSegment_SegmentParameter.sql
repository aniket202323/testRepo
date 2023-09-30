CREATE TABLE [dbo].[ProcessSegment_SegmentParameter] (
    [r_Order]                    INT              NULL,
    [Value]                      SQL_VARIANT      NULL,
    [Quality]                    SMALLINT         NULL,
    [TimeStamp]                  DATETIME         NULL,
    [Version]                    BIGINT           NULL,
    [ProcSegId]                  UNIQUEIDENTIFIER NOT NULL,
    [SegmentParameterPropertyId] UNIQUEIDENTIFIER NOT NULL,
    [ItemId]                     UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([ProcSegId] ASC, [SegmentParameterPropertyId] ASC),
    CONSTRAINT [ProcessSegment_SegmentParameter_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [ProcessSegment_SegmentParameter_ProcSeg_Relation1] FOREIGN KEY ([ProcSegId]) REFERENCES [dbo].[ProcSeg] ([ProcSegId]),
    CONSTRAINT [ProcessSegment_SegmentParameter_SegmentParameter_Relation1] FOREIGN KEY ([SegmentParameterPropertyId]) REFERENCES [dbo].[SegmentParameter] ([SegmentParameterPropertyId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ProcessSegment_SegmentParameter_SegmentParameterPropertyId]
    ON [dbo].[ProcessSegment_SegmentParameter]([SegmentParameterPropertyId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_ProcessSegment_SegmentParameter_ItemId]
    ON [dbo].[ProcessSegment_SegmentParameter]([ItemId] ASC);

