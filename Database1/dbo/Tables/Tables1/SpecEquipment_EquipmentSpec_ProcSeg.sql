CREATE TABLE [dbo].[SpecEquipment_EquipmentSpec_ProcSeg] (
    [SpecEquipment_EquipmentSpec_ProcSegId] UNIQUEIDENTIFIER NOT NULL,
    [SpecificationType]                     NVARCHAR (255)   NULL,
    [Version]                               BIGINT           NULL,
    [EquipmentClassName]                    NVARCHAR (200)   NULL,
    [EquipmentId]                           UNIQUEIDENTIFIER NULL,
    [EquipmentSpec_ProcSegId]               UNIQUEIDENTIFIER NULL,
    [ProcSegId]                             UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([SpecEquipment_EquipmentSpec_ProcSegId] ASC),
    CONSTRAINT [SpecEquipment_EquipmentSpec_ProcSeg_Equipment_Relation1] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId]),
    CONSTRAINT [SpecEquipment_EquipmentSpec_ProcSeg_EquipmentClass_Relation1] FOREIGN KEY ([EquipmentClassName]) REFERENCES [dbo].[EquipmentClass] ([EquipmentClassName]) ON UPDATE CASCADE,
    CONSTRAINT [SpecEquipment_EquipmentSpec_ProcSeg_EquipmentSpec_ProcSeg_Relation1] FOREIGN KEY ([EquipmentSpec_ProcSegId], [ProcSegId]) REFERENCES [dbo].[EquipmentSpec_ProcSeg] ([EquipmentSpec_ProcSegId], [ProcSegId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SpecEquipment_EquipmentSpec_ProcSeg_EquipmentClassName]
    ON [dbo].[SpecEquipment_EquipmentSpec_ProcSeg]([EquipmentClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecEquipment_EquipmentSpec_ProcSeg_EquipmentId]
    ON [dbo].[SpecEquipment_EquipmentSpec_ProcSeg]([EquipmentId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecEquipment_EquipmentSpec_ProcSeg_EquipmentSpec_ProcSegId_ProcSegId]
    ON [dbo].[SpecEquipment_EquipmentSpec_ProcSeg]([EquipmentSpec_ProcSegId] ASC, [ProcSegId] ASC);

