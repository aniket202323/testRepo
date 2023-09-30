CREATE TABLE [dbo].[SpecMaterial_MaterialSpec_ProcSeg] (
    [SpecMaterial_MaterialSpec_ProcSegId] UNIQUEIDENTIFIER NOT NULL,
    [SpecificationType]                   NVARCHAR (255)   NULL,
    [Version]                             BIGINT           NULL,
    [MaterialDefinitionId]                UNIQUEIDENTIFIER NULL,
    [MaterialClassName]                   NVARCHAR (200)   NULL,
    [MaterialLotId]                       UNIQUEIDENTIFIER NULL,
    [MaterialSublotId]                    UNIQUEIDENTIFIER NULL,
    [MaterialSpec_ProcSegId]              UNIQUEIDENTIFIER NULL,
    [ProcSegId]                           UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([SpecMaterial_MaterialSpec_ProcSegId] ASC),
    CONSTRAINT [SpecMaterial_MaterialSpec_ProcSeg_MaterialClass_Relation1] FOREIGN KEY ([MaterialClassName]) REFERENCES [dbo].[MaterialClass] ([MaterialClassName]) ON UPDATE CASCADE,
    CONSTRAINT [SpecMaterial_MaterialSpec_ProcSeg_MaterialDefinition_Relation1] FOREIGN KEY ([MaterialDefinitionId]) REFERENCES [dbo].[MaterialDefinition] ([MaterialDefinitionId]),
    CONSTRAINT [SpecMaterial_MaterialSpec_ProcSeg_MaterialLot_Relation1] FOREIGN KEY ([MaterialLotId]) REFERENCES [dbo].[MaterialLot] ([MaterialLotId]),
    CONSTRAINT [SpecMaterial_MaterialSpec_ProcSeg_MaterialSpec_ProcSeg_Relation1] FOREIGN KEY ([MaterialSpec_ProcSegId], [ProcSegId]) REFERENCES [dbo].[MaterialSpec_ProcSeg] ([MaterialSpec_ProcSegId], [ProcSegId]),
    CONSTRAINT [SpecMaterial_MaterialSpec_ProcSeg_MaterialSublot_Relation1] FOREIGN KEY ([MaterialSublotId]) REFERENCES [dbo].[MaterialSublot] ([MaterialSublotId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_MaterialSpec_ProcSeg_MaterialDefinitionId]
    ON [dbo].[SpecMaterial_MaterialSpec_ProcSeg]([MaterialDefinitionId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_MaterialSpec_ProcSeg_MaterialClassName]
    ON [dbo].[SpecMaterial_MaterialSpec_ProcSeg]([MaterialClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_MaterialSpec_ProcSeg_MaterialLotId]
    ON [dbo].[SpecMaterial_MaterialSpec_ProcSeg]([MaterialLotId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_MaterialSpec_ProcSeg_MaterialSublotId]
    ON [dbo].[SpecMaterial_MaterialSpec_ProcSeg]([MaterialSublotId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_MaterialSpec_ProcSeg_MaterialSpec_ProcSegId_ProcSegId]
    ON [dbo].[SpecMaterial_MaterialSpec_ProcSeg]([MaterialSpec_ProcSegId] ASC, [ProcSegId] ASC);

