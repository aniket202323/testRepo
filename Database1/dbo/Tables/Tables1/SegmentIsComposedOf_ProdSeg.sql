CREATE TABLE [dbo].[SegmentIsComposedOf_ProdSeg] (
    [Name]                   NVARCHAR (50)    NOT NULL,
    [r_Order]                INT              NULL,
    [Version]                BIGINT           NULL,
    [ParentSegmentProdSegId] UNIQUEIDENTIFIER NOT NULL,
    [ChildSegmentProdSegId]  UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([ParentSegmentProdSegId] ASC, [Name] ASC),
    CONSTRAINT [SegmentIsComposedOf_ProdSeg_ProdSeg_Relation1] FOREIGN KEY ([ParentSegmentProdSegId]) REFERENCES [dbo].[ProdSeg] ([ProdSegId]),
    CONSTRAINT [SegmentIsComposedOf_ProdSeg_ProdSeg_Relation2] FOREIGN KEY ([ChildSegmentProdSegId]) REFERENCES [dbo].[ProdSeg] ([ProdSegId])
);


GO
CREATE NONCLUSTERED INDEX [IX_SegmentIsComposedOf_ProdSeg_Name]
    ON [dbo].[SegmentIsComposedOf_ProdSeg]([Name] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SegmentIsComposedOf_ProdSeg_ChildSegmentProdSegId]
    ON [dbo].[SegmentIsComposedOf_ProdSeg]([ChildSegmentProdSegId] ASC);

