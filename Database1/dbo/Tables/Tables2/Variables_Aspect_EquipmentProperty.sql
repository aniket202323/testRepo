CREATE TABLE [dbo].[Variables_Aspect_EquipmentProperty] (
    [Variables_Aspect_EquipmentPropertyPkId] UNIQUEIDENTIFIER NOT NULL,
    [Version]                                BIGINT           NULL,
    [Var_Id]                                 INT              NULL,
    [Origin2EquipmentClassName]              NVARCHAR (200)   NULL,
    [Origin2PropertyName]                    NVARCHAR (200)   NULL,
    [Origin1EquipmentId]                     UNIQUEIDENTIFIER NULL,
    [Origin1Name]                            NVARCHAR (255)   NULL,
    PRIMARY KEY CLUSTERED ([Variables_Aspect_EquipmentPropertyPkId] ASC),
    CONSTRAINT [Variables_Aspect_EquipmentProperty_Property_Equipment_EquipmentClass_Relation1] FOREIGN KEY ([Origin1EquipmentId], [Origin1Name]) REFERENCES [dbo].[Property_Equipment_EquipmentClass] ([EquipmentId], [Name]) ON UPDATE CASCADE,
    CONSTRAINT [Variables_Aspect_EquipmentProperty_Property_EquipmentClass_Relation1] FOREIGN KEY ([Origin2EquipmentClassName], [Origin2PropertyName]) REFERENCES [dbo].[Property_EquipmentClass] ([EquipmentClassName], [PropertyName]) ON UPDATE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Variables_Aspect_EquipmentProperty_Origin2EquipmentClassName_Origin2PropertyName_Origin1EquipmentId_Origin1Name]
    ON [dbo].[Variables_Aspect_EquipmentProperty]([Origin2EquipmentClassName] ASC, [Origin2PropertyName] ASC, [Origin1EquipmentId] ASC, [Origin1Name] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Variables_Aspect_EquipmentProperty_Var_Id]
    ON [dbo].[Variables_Aspect_EquipmentProperty]([Var_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Variables_Aspect_EquipmentProperty_Origin2EquipmentClassName_Origin2PropertyName]
    ON [dbo].[Variables_Aspect_EquipmentProperty]([Origin2EquipmentClassName] ASC, [Origin2PropertyName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Variables_Aspect_EquipmentProperty_Origin1EquipmentId_Origin1Name]
    ON [dbo].[Variables_Aspect_EquipmentProperty]([Origin1EquipmentId] ASC, [Origin1Name] ASC);

