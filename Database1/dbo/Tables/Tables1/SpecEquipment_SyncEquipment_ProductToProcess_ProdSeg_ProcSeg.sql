CREATE TABLE [dbo].[SpecEquipment_SyncEquipment_ProductToProcess_ProdSeg_ProcSeg] (
    [SpecEquipment_SyncEquipment_ProductToProcess_ProdSeg_ProcSegId] UNIQUEIDENTIFIER NOT NULL,
    [SpecificationType]                                              NVARCHAR (255)   NULL,
    [Version]                                                        BIGINT           NULL,
    [EquipmentClassName]                                             NVARCHAR (200)   NULL,
    [EquipmentId]                                                    UNIQUEIDENTIFIER NULL,
    [ProdSegId]                                                      UNIQUEIDENTIFIER NULL,
    [ProcSegId]                                                      UNIQUEIDENTIFIER NULL,
    [EquipmentSpec_ProcSegId]                                        UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([SpecEquipment_SyncEquipment_ProductToProcess_ProdSeg_ProcSegId] ASC),
    CONSTRAINT [SpecEquipment_SyncEquipment_ProductToProcess_ProdSeg_ProcSeg_Equipment_Relation1] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId]),
    CONSTRAINT [SpecEquipment_SyncEquipment_ProductToProcess_ProdSeg_ProcSeg_EquipmentClass_Relation1] FOREIGN KEY ([EquipmentClassName]) REFERENCES [dbo].[EquipmentClass] ([EquipmentClassName]) ON UPDATE CASCADE,
    CONSTRAINT [SpecEquipment_SyncEquipment_ProductToProcess_ProdSeg_ProcSeg_SyncEquipment_ProductToProcess_ProdSeg_ProcSeg_Relation1] FOREIGN KEY ([ProdSegId], [ProcSegId], [EquipmentSpec_ProcSegId]) REFERENCES [dbo].[SyncEquipment_ProductToProcess_ProdSeg_ProcSeg] ([ProdSegId], [ProcSegId], [EquipmentSpec_ProcSegId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SpecEquipment_SyncEquipment_ProductToProcess_ProdSeg_ProcSeg_EquipmentClassName]
    ON [dbo].[SpecEquipment_SyncEquipment_ProductToProcess_ProdSeg_ProcSeg]([EquipmentClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecEquipment_SyncEquipment_ProductToProcess_ProdSeg_ProcSeg_EquipmentId]
    ON [dbo].[SpecEquipment_SyncEquipment_ProductToProcess_ProdSeg_ProcSeg]([EquipmentId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecEquipment_SyncEquipment_ProductToProcess_ProdSeg_ProcSeg_ProdSegId_ProcSegId_EquipmentSpec_ProcSegId]
    ON [dbo].[SpecEquipment_SyncEquipment_ProductToProcess_ProdSeg_ProcSeg]([ProdSegId] ASC, [ProcSegId] ASC, [EquipmentSpec_ProcSegId] ASC);

