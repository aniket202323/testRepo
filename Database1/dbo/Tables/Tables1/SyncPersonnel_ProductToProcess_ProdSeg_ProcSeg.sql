CREATE TABLE [dbo].[SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg] (
    [S95Type]                 NVARCHAR (50)    NULL,
    [Quantity]                FLOAT (53)       NULL,
    [SpecifiedResourcesSet]   BIT              NULL,
    [QuantitySet]             BIT              NULL,
    [Version]                 BIGINT           NULL,
    [ProdSegId]               UNIQUEIDENTIFIER NOT NULL,
    [ProcSegId]               UNIQUEIDENTIFIER NOT NULL,
    [PersonnelSpec_ProcSegId] UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([ProdSegId] ASC, [ProcSegId] ASC, [PersonnelSpec_ProcSegId] ASC),
    CONSTRAINT [SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg_PersonnelSpec_ProcSeg_Relation1] FOREIGN KEY ([PersonnelSpec_ProcSegId], [ProcSegId]) REFERENCES [dbo].[PersonnelSpec_ProcSeg] ([PersonnelSpec_ProcSegId], [ProcSegId]) ON UPDATE CASCADE,
    CONSTRAINT [SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg_ProductToProcess_Relation1] FOREIGN KEY ([ProdSegId], [ProcSegId]) REFERENCES [dbo].[ProductToProcess] ([ProdSegId], [ProcSegId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg_PersonnelSpec_ProcSegId_ProcSegId]
    ON [dbo].[SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg]([PersonnelSpec_ProcSegId] ASC, [ProcSegId] ASC);

