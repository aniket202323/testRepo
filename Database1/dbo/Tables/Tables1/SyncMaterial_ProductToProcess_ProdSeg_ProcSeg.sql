CREATE TABLE [dbo].[SyncMaterial_ProductToProcess_ProdSeg_ProcSeg] (
    [S95Type]                NVARCHAR (50)    NULL,
    [Quantity]               FLOAT (53)       NULL,
    [SpecifiedResourcesSet]  BIT              NULL,
    [QuantitySet]            BIT              NULL,
    [Version]                BIGINT           NULL,
    [ProdSegId]              UNIQUEIDENTIFIER NOT NULL,
    [ProcSegId]              UNIQUEIDENTIFIER NOT NULL,
    [MaterialSpec_ProcSegId] UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([ProdSegId] ASC, [ProcSegId] ASC, [MaterialSpec_ProcSegId] ASC),
    CONSTRAINT [SyncMaterial_ProductToProcess_ProdSeg_ProcSeg_MaterialSpec_ProcSeg_Relation1] FOREIGN KEY ([MaterialSpec_ProcSegId], [ProcSegId]) REFERENCES [dbo].[MaterialSpec_ProcSeg] ([MaterialSpec_ProcSegId], [ProcSegId]) ON UPDATE CASCADE,
    CONSTRAINT [SyncMaterial_ProductToProcess_ProdSeg_ProcSeg_ProductToProcess_Relation1] FOREIGN KEY ([ProdSegId], [ProcSegId]) REFERENCES [dbo].[ProductToProcess] ([ProdSegId], [ProcSegId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg_MaterialSpec_ProcSegId_ProcSegId]
    ON [dbo].[SyncMaterial_ProductToProcess_ProdSeg_ProcSeg]([MaterialSpec_ProcSegId] ASC, [ProcSegId] ASC);

