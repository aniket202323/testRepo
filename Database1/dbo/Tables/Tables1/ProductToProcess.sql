CREATE TABLE [dbo].[ProductToProcess] (
    [BaseSegmentOrder] INT              NULL,
    [Version]          BIGINT           NULL,
    [ProdSegId]        UNIQUEIDENTIFIER NOT NULL,
    [ProcSegId]        UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([ProdSegId] ASC, [ProcSegId] ASC),
    CONSTRAINT [ProductToProcess_ProcSeg_Relation1] FOREIGN KEY ([ProcSegId]) REFERENCES [dbo].[ProcSeg] ([ProcSegId]),
    CONSTRAINT [ProductToProcess_ProdSeg_Relation1] FOREIGN KEY ([ProdSegId]) REFERENCES [dbo].[ProdSeg] ([ProdSegId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ProductToProcess_ProcSegId]
    ON [dbo].[ProductToProcess]([ProcSegId] ASC);

