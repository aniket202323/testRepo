CREATE TABLE [dbo].[SegmentRequirement_SegmentParameter] (
    [r_Order]                    INT              NULL,
    [Value]                      SQL_VARIANT      NULL,
    [Quality]                    SMALLINT         NULL,
    [TimeStamp]                  DATETIME         NULL,
    [Version]                    BIGINT           NULL,
    [SegReqId]                   UNIQUEIDENTIFIER NOT NULL,
    [WorkRequestId]              UNIQUEIDENTIFIER NOT NULL,
    [SegmentParameterPropertyId] UNIQUEIDENTIFIER NOT NULL,
    [ItemId]                     UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([SegReqId] ASC, [WorkRequestId] ASC, [SegmentParameterPropertyId] ASC),
    CONSTRAINT [SegmentRequirement_SegmentParameter_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [SegmentRequirement_SegmentParameter_SegmentParameter_Relation1] FOREIGN KEY ([SegmentParameterPropertyId]) REFERENCES [dbo].[SegmentParameter] ([SegmentParameterPropertyId]),
    CONSTRAINT [SegmentRequirement_SegmentParameter_SegReq_Relation1] FOREIGN KEY ([SegReqId], [WorkRequestId]) REFERENCES [dbo].[SegReq] ([SegReqId], [WorkRequestId])
);


GO
ALTER TABLE [dbo].[SegmentRequirement_SegmentParameter] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_SegmentRequirement_SegmentParameter_SegmentParameterPropertyId]
    ON [dbo].[SegmentRequirement_SegmentParameter]([SegmentParameterPropertyId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SegmentRequirement_SegmentParameter_ItemId]
    ON [dbo].[SegmentRequirement_SegmentParameter]([ItemId] ASC);

