CREATE TABLE [dbo].[MatActualPropTemplate] (
    [MatActualPropTemplateId]             UNIQUEIDENTIFIER NOT NULL,
    [Version]                             BIGINT           NULL,
    [SpecMaterial_MaterialSpec_ProcSegId] UNIQUEIDENTIFIER NOT NULL,
    [PropertyMaterialDefinitionId]        UNIQUEIDENTIFIER NULL,
    [PropertyName]                        NVARCHAR (255)   NULL,
    [ClassPropertyMaterialClassName]      NVARCHAR (200)   NULL,
    [ClassPropertyPropertyName]           NVARCHAR (200)   NULL,
    PRIMARY KEY CLUSTERED ([SpecMaterial_MaterialSpec_ProcSegId] ASC, [MatActualPropTemplateId] ASC),
    CONSTRAINT [MatActualPropTemplate_Property_MaterialClass_Relation1] FOREIGN KEY ([ClassPropertyMaterialClassName], [ClassPropertyPropertyName]) REFERENCES [dbo].[Property_MaterialClass] ([MaterialClassName], [PropertyName]),
    CONSTRAINT [MatActualPropTemplate_Property_MaterialDefinition_MaterialClass_Relation1] FOREIGN KEY ([PropertyMaterialDefinitionId], [PropertyName]) REFERENCES [dbo].[Property_MaterialDefinition_MaterialClass] ([MaterialDefinitionId], [Name]),
    CONSTRAINT [MatActualPropTemplate_SpecMaterial_MaterialSpec_ProcSeg_Relation1] FOREIGN KEY ([SpecMaterial_MaterialSpec_ProcSegId]) REFERENCES [dbo].[SpecMaterial_MaterialSpec_ProcSeg] ([SpecMaterial_MaterialSpec_ProcSegId])
);


GO
CREATE NONCLUSTERED INDEX [NC_MatActualPropTemplate_PropertyMaterialDefinitionId_PropertyName]
    ON [dbo].[MatActualPropTemplate]([PropertyMaterialDefinitionId] ASC, [PropertyName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_MatActualPropTemplate_ClassPropertyMaterialClassName_ClassPropertyPropertyName]
    ON [dbo].[MatActualPropTemplate]([ClassPropertyMaterialClassName] ASC, [ClassPropertyPropertyName] ASC);

