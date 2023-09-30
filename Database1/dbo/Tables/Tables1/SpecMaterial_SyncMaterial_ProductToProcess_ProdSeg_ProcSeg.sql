CREATE TABLE [dbo].[SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg] (
    [SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSegId] UNIQUEIDENTIFIER NOT NULL,
    [SpecificationType]                                            NVARCHAR (255)   NULL,
    [Version]                                                      BIGINT           NULL,
    [MaterialDefinitionId]                                         UNIQUEIDENTIFIER NULL,
    [MaterialClassName]                                            NVARCHAR (200)   NULL,
    [MaterialLotId]                                                UNIQUEIDENTIFIER NULL,
    [MaterialSublotId]                                             UNIQUEIDENTIFIER NULL,
    [ProdSegId]                                                    UNIQUEIDENTIFIER NULL,
    [ProcSegId]                                                    UNIQUEIDENTIFIER NULL,
    [MaterialSpec_ProcSegId]                                       UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSegId] ASC),
    CONSTRAINT [SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg_MaterialClass_Relation1] FOREIGN KEY ([MaterialClassName]) REFERENCES [dbo].[MaterialClass] ([MaterialClassName]) ON UPDATE CASCADE,
    CONSTRAINT [SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg_MaterialDefinition_Relation1] FOREIGN KEY ([MaterialDefinitionId]) REFERENCES [dbo].[MaterialDefinition] ([MaterialDefinitionId]),
    CONSTRAINT [SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg_MaterialLot_Relation1] FOREIGN KEY ([MaterialLotId]) REFERENCES [dbo].[MaterialLot] ([MaterialLotId]),
    CONSTRAINT [SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg_MaterialSublot_Relation1] FOREIGN KEY ([MaterialSublotId]) REFERENCES [dbo].[MaterialSublot] ([MaterialSublotId]),
    CONSTRAINT [SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg_Relation1] FOREIGN KEY ([ProdSegId], [ProcSegId], [MaterialSpec_ProcSegId]) REFERENCES [dbo].[SyncMaterial_ProductToProcess_ProdSeg_ProcSeg] ([ProdSegId], [ProcSegId], [MaterialSpec_ProcSegId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg_MaterialDefinitionId]
    ON [dbo].[SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg]([MaterialDefinitionId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg_MaterialClassName]
    ON [dbo].[SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg]([MaterialClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg_MaterialLotId]
    ON [dbo].[SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg]([MaterialLotId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg_MaterialSublotId]
    ON [dbo].[SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg]([MaterialSublotId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg_ProdSegId_ProcSegId_MaterialSpec_ProcSegId]
    ON [dbo].[SpecMaterial_SyncMaterial_ProductToProcess_ProdSeg_ProcSeg]([ProdSegId] ASC, [ProcSegId] ASC, [MaterialSpec_ProcSegId] ASC);

