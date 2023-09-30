CREATE TABLE [dbo].[ProductSegment_SegmentParameter] (
    [r_Order]                    INT              NULL,
    [Value]                      SQL_VARIANT      NULL,
    [Quality]                    SMALLINT         NULL,
    [TimeStamp]                  DATETIME         NULL,
    [Version]                    BIGINT           NULL,
    [ProdSegId]                  UNIQUEIDENTIFIER NOT NULL,
    [SegmentParameterPropertyId] UNIQUEIDENTIFIER NOT NULL,
    [ItemId]                     UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([ProdSegId] ASC, [SegmentParameterPropertyId] ASC),
    CONSTRAINT [ProductSegment_SegmentParameter_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [ProductSegment_SegmentParameter_ProdSeg_Relation1] FOREIGN KEY ([ProdSegId]) REFERENCES [dbo].[ProdSeg] ([ProdSegId]),
    CONSTRAINT [ProductSegment_SegmentParameter_SegmentParameter_Relation1] FOREIGN KEY ([SegmentParameterPropertyId]) REFERENCES [dbo].[SegmentParameter] ([SegmentParameterPropertyId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ProductSegment_SegmentParameter_SegmentParameterPropertyId]
    ON [dbo].[ProductSegment_SegmentParameter]([SegmentParameterPropertyId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_ProductSegment_SegmentParameter_ItemId]
    ON [dbo].[ProductSegment_SegmentParameter]([ItemId] ASC);

