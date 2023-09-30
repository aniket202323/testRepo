CREATE TABLE [dbo].[EqActualPropTemplate] (
    [EqActualPropTemplateId]                UNIQUEIDENTIFIER NOT NULL,
    [Version]                               BIGINT           NULL,
    [SpecEquipment_EquipmentSpec_ProcSegId] UNIQUEIDENTIFIER NOT NULL,
    [PropertyEquipmentId]                   UNIQUEIDENTIFIER NULL,
    [PropertyName]                          NVARCHAR (255)   NULL,
    [ClassPropertyEquipmentClassName]       NVARCHAR (200)   NULL,
    [ClassPropertyPropertyName]             NVARCHAR (200)   NULL,
    PRIMARY KEY CLUSTERED ([SpecEquipment_EquipmentSpec_ProcSegId] ASC, [EqActualPropTemplateId] ASC),
    CONSTRAINT [EqActualPropTemplate_Property_Equipment_EquipmentClass_Relation1] FOREIGN KEY ([PropertyEquipmentId], [PropertyName]) REFERENCES [dbo].[Property_Equipment_EquipmentClass] ([EquipmentId], [Name]),
    CONSTRAINT [EqActualPropTemplate_Property_EquipmentClass_Relation1] FOREIGN KEY ([ClassPropertyEquipmentClassName], [ClassPropertyPropertyName]) REFERENCES [dbo].[Property_EquipmentClass] ([EquipmentClassName], [PropertyName]),
    CONSTRAINT [EqActualPropTemplate_SpecEquipment_EquipmentSpec_ProcSeg_Relation1] FOREIGN KEY ([SpecEquipment_EquipmentSpec_ProcSegId]) REFERENCES [dbo].[SpecEquipment_EquipmentSpec_ProcSeg] ([SpecEquipment_EquipmentSpec_ProcSegId])
);


GO
CREATE NONCLUSTERED INDEX [NC_EqActualPropTemplate_PropertyEquipmentId_PropertyName]
    ON [dbo].[EqActualPropTemplate]([PropertyEquipmentId] ASC, [PropertyName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_EqActualPropTemplate_ClassPropertyEquipmentClassName_ClassPropertyPropertyName]
    ON [dbo].[EqActualPropTemplate]([ClassPropertyEquipmentClassName] ASC, [ClassPropertyPropertyName] ASC);

