CREATE TABLE [dbo].[SpecMaterial_MaterialSpec_ProdSeg] (
    [SpecMaterial_MaterialSpec_ProdSegId] UNIQUEIDENTIFIER NOT NULL,
    [SpecificationType]                   NVARCHAR (255)   NULL,
    [Version]                             BIGINT           NULL,
    [MaterialDefinitionId]                UNIQUEIDENTIFIER NULL,
    [MaterialClassName]                   NVARCHAR (200)   NULL,
    [MaterialLotId]                       UNIQUEIDENTIFIER NULL,
    [MaterialSublotId]                    UNIQUEIDENTIFIER NULL,
    [MaterialSpec_ProdSegId]              UNIQUEIDENTIFIER NULL,
    [ProdSegId]                           UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([SpecMaterial_MaterialSpec_ProdSegId] ASC),
    CONSTRAINT [SpecMaterial_MaterialSpec_ProdSeg_MaterialClass_Relation1] FOREIGN KEY ([MaterialClassName]) REFERENCES [dbo].[MaterialClass] ([MaterialClassName]) ON UPDATE CASCADE,
    CONSTRAINT [SpecMaterial_MaterialSpec_ProdSeg_MaterialDefinition_Relation1] FOREIGN KEY ([MaterialDefinitionId]) REFERENCES [dbo].[MaterialDefinition] ([MaterialDefinitionId]),
    CONSTRAINT [SpecMaterial_MaterialSpec_ProdSeg_MaterialLot_Relation1] FOREIGN KEY ([MaterialLotId]) REFERENCES [dbo].[MaterialLot] ([MaterialLotId]),
    CONSTRAINT [SpecMaterial_MaterialSpec_ProdSeg_MaterialSpec_ProdSeg_Relation1] FOREIGN KEY ([MaterialSpec_ProdSegId], [ProdSegId]) REFERENCES [dbo].[MaterialSpec_ProdSeg] ([MaterialSpec_ProdSegId], [ProdSegId]),
    CONSTRAINT [SpecMaterial_MaterialSpec_ProdSeg_MaterialSublot_Relation1] FOREIGN KEY ([MaterialSublotId]) REFERENCES [dbo].[MaterialSublot] ([MaterialSublotId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_MaterialSpec_ProdSeg_MaterialDefinitionId]
    ON [dbo].[SpecMaterial_MaterialSpec_ProdSeg]([MaterialDefinitionId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_MaterialSpec_ProdSeg_MaterialClassName]
    ON [dbo].[SpecMaterial_MaterialSpec_ProdSeg]([MaterialClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_MaterialSpec_ProdSeg_MaterialLotId]
    ON [dbo].[SpecMaterial_MaterialSpec_ProdSeg]([MaterialLotId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_MaterialSpec_ProdSeg_MaterialSublotId]
    ON [dbo].[SpecMaterial_MaterialSpec_ProdSeg]([MaterialSublotId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_MaterialSpec_ProdSeg_MaterialSpec_ProdSegId_ProdSegId]
    ON [dbo].[SpecMaterial_MaterialSpec_ProdSeg]([MaterialSpec_ProdSegId] ASC, [ProdSegId] ASC);

