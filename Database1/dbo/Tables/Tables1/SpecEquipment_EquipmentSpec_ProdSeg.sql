CREATE TABLE [dbo].[SpecEquipment_EquipmentSpec_ProdSeg] (
    [SpecEquipment_EquipmentSpec_ProdSegId] UNIQUEIDENTIFIER NOT NULL,
    [SpecificationType]                     NVARCHAR (255)   NULL,
    [Version]                               BIGINT           NULL,
    [EquipmentClassName]                    NVARCHAR (200)   NULL,
    [EquipmentId]                           UNIQUEIDENTIFIER NULL,
    [EquipmentSpec_ProdSegId]               UNIQUEIDENTIFIER NULL,
    [ProdSegId]                             UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([SpecEquipment_EquipmentSpec_ProdSegId] ASC),
    CONSTRAINT [SpecEquipment_EquipmentSpec_ProdSeg_Equipment_Relation1] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId]),
    CONSTRAINT [SpecEquipment_EquipmentSpec_ProdSeg_EquipmentClass_Relation1] FOREIGN KEY ([EquipmentClassName]) REFERENCES [dbo].[EquipmentClass] ([EquipmentClassName]) ON UPDATE CASCADE,
    CONSTRAINT [SpecEquipment_EquipmentSpec_ProdSeg_EquipmentSpec_ProdSeg_Relation1] FOREIGN KEY ([EquipmentSpec_ProdSegId], [ProdSegId]) REFERENCES [dbo].[EquipmentSpec_ProdSeg] ([EquipmentSpec_ProdSegId], [ProdSegId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SpecEquipment_EquipmentSpec_ProdSeg_EquipmentClassName]
    ON [dbo].[SpecEquipment_EquipmentSpec_ProdSeg]([EquipmentClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecEquipment_EquipmentSpec_ProdSeg_EquipmentId]
    ON [dbo].[SpecEquipment_EquipmentSpec_ProdSeg]([EquipmentId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecEquipment_EquipmentSpec_ProdSeg_EquipmentSpec_ProdSegId_ProdSegId]
    ON [dbo].[SpecEquipment_EquipmentSpec_ProdSeg]([EquipmentSpec_ProdSegId] ASC, [ProdSegId] ASC);

