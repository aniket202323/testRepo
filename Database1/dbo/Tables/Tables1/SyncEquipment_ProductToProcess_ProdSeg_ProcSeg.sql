CREATE TABLE [dbo].[SyncEquipment_ProductToProcess_ProdSeg_ProcSeg] (
    [S95Type]                 NVARCHAR (50)    NULL,
    [Quantity]                FLOAT (53)       NULL,
    [SpecifiedResourcesSet]   BIT              NULL,
    [QuantitySet]             BIT              NULL,
    [Version]                 BIGINT           NULL,
    [ProdSegId]               UNIQUEIDENTIFIER NOT NULL,
    [ProcSegId]               UNIQUEIDENTIFIER NOT NULL,
    [EquipmentSpec_ProcSegId] UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([ProdSegId] ASC, [ProcSegId] ASC, [EquipmentSpec_ProcSegId] ASC),
    CONSTRAINT [SyncEquipment_ProductToProcess_ProdSeg_ProcSeg_EquipmentSpec_ProcSeg_Relation1] FOREIGN KEY ([EquipmentSpec_ProcSegId], [ProcSegId]) REFERENCES [dbo].[EquipmentSpec_ProcSeg] ([EquipmentSpec_ProcSegId], [ProcSegId]) ON UPDATE CASCADE,
    CONSTRAINT [SyncEquipment_ProductToProcess_ProdSeg_ProcSeg_ProductToProcess_Relation1] FOREIGN KEY ([ProdSegId], [ProcSegId]) REFERENCES [dbo].[ProductToProcess] ([ProdSegId], [ProcSegId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SyncEquipment_ProductToProcess_ProdSeg_ProcSeg_EquipmentSpec_ProcSegId_ProcSegId]
    ON [dbo].[SyncEquipment_ProductToProcess_ProdSeg_ProcSeg]([EquipmentSpec_ProcSegId] ASC, [ProcSegId] ASC);

