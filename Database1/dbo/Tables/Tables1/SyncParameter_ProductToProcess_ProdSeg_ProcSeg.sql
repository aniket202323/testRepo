CREATE TABLE [dbo].[SyncParameter_ProductToProcess_ProdSeg_ProcSeg] (
    [ParameterSet]               BIT              NULL,
    [r_Order]                    INT              NULL,
    [Value]                      SQL_VARIANT      NULL,
    [Quality]                    SMALLINT         NULL,
    [TimeStamp]                  DATETIME         NULL,
    [Version]                    BIGINT           NULL,
    [ProcSegId]                  UNIQUEIDENTIFIER NOT NULL,
    [SegmentParameterPropertyId] UNIQUEIDENTIFIER NOT NULL,
    [ProdSegId]                  UNIQUEIDENTIFIER NOT NULL,
    [ItemId]                     UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([ProdSegId] ASC, [ProcSegId] ASC, [SegmentParameterPropertyId] ASC),
    CONSTRAINT [SyncParameter_ProductToProcess_ProdSeg_ProcSeg_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [SyncParameter_ProductToProcess_ProdSeg_ProcSeg_ProcessSegment_SegmentParameter_Relation1] FOREIGN KEY ([ProcSegId], [SegmentParameterPropertyId]) REFERENCES [dbo].[ProcessSegment_SegmentParameter] ([ProcSegId], [SegmentParameterPropertyId]) ON UPDATE CASCADE,
    CONSTRAINT [SyncParameter_ProductToProcess_ProdSeg_ProcSeg_ProductToProcess_Relation1] FOREIGN KEY ([ProdSegId], [ProcSegId]) REFERENCES [dbo].[ProductToProcess] ([ProdSegId], [ProcSegId]),
    CONSTRAINT [SyncParameter_ProductToProcess_ProdSeg_ProcSeg_SegmentParameter_Relation1] FOREIGN KEY ([SegmentParameterPropertyId]) REFERENCES [dbo].[SegmentParameter] ([SegmentParameterPropertyId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SyncParameter_ProductToProcess_ProdSeg_ProcSeg_ProcSegId_SegmentParameterPropertyId]
    ON [dbo].[SyncParameter_ProductToProcess_ProdSeg_ProcSeg]([ProcSegId] ASC, [SegmentParameterPropertyId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SyncParameter_ProductToProcess_ProdSeg_ProcSeg_SegmentParameterPropertyId]
    ON [dbo].[SyncParameter_ProductToProcess_ProdSeg_ProcSeg]([SegmentParameterPropertyId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SyncParameter_ProductToProcess_ProdSeg_ProcSeg_ItemId]
    ON [dbo].[SyncParameter_ProductToProcess_ProdSeg_ProcSeg]([ItemId] ASC);

