CREATE TABLE [dbo].[PAEquipment_Aspect_SOAEquipment] (
    [PAEquipment_Aspect_SOAEquipmentPkId] UNIQUEIDENTIFIER NOT NULL,
    [Version]                             BIGINT           NULL,
    [PU_Id]                               INT              NULL,
    [PL_Id]                               INT              NULL,
    [Dept_Id]                             INT              NULL,
    [Origin2EquipmentClassName]           NVARCHAR (200)   NULL,
    [Origin1EquipmentId]                  UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([PAEquipment_Aspect_SOAEquipmentPkId] ASC),
    CONSTRAINT [PAEquipment_Aspect_SOAEquipment_Departments_Base_Relation1] FOREIGN KEY ([Dept_Id]) REFERENCES [dbo].[Departments_Base] ([Dept_Id]) ON DELETE SET NULL,
    CONSTRAINT [PAEquipment_Aspect_SOAEquipment_Equipment_Relation1] FOREIGN KEY ([Origin1EquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId]) ON UPDATE CASCADE,
    CONSTRAINT [PAEquipment_Aspect_SOAEquipment_EquipmentClass_Relation1] FOREIGN KEY ([Origin2EquipmentClassName]) REFERENCES [dbo].[EquipmentClass] ([EquipmentClassName]) ON UPDATE CASCADE,
    CONSTRAINT [PAEquipment_Aspect_SOAEquipment_Prod_Lines_Base_Relation1] FOREIGN KEY ([PL_Id]) REFERENCES [dbo].[Prod_Lines_Base] ([PL_Id]) ON DELETE SET NULL,
    CONSTRAINT [PAEquipment_Aspect_SOAEquipment_Prod_Units_Base_Relation1] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]) ON DELETE SET NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PAEquipment_Aspect_SOAEquipment_PU_Id_PL_Id_Dept_Id]
    ON [dbo].[PAEquipment_Aspect_SOAEquipment]([PU_Id] ASC, [PL_Id] ASC, [Dept_Id] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PAEquipment_Aspect_SOAEquipment_Origin2EquipmentClassName_Origin1EquipmentId]
    ON [dbo].[PAEquipment_Aspect_SOAEquipment]([Origin2EquipmentClassName] ASC, [Origin1EquipmentId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PAEquipment_Aspect_SOAEquipment_PU_Id]
    ON [dbo].[PAEquipment_Aspect_SOAEquipment]([PU_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PAEquipment_Aspect_SOAEquipment_PL_Id]
    ON [dbo].[PAEquipment_Aspect_SOAEquipment]([PL_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PAEquipment_Aspect_SOAEquipment_Dept_Id]
    ON [dbo].[PAEquipment_Aspect_SOAEquipment]([Dept_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PAEquipment_Aspect_SOAEquipment_Origin2EquipmentClassName]
    ON [dbo].[PAEquipment_Aspect_SOAEquipment]([Origin2EquipmentClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PAEquipment_Aspect_SOAEquipment_Origin1EquipmentId]
    ON [dbo].[PAEquipment_Aspect_SOAEquipment]([Origin1EquipmentId] ASC);

