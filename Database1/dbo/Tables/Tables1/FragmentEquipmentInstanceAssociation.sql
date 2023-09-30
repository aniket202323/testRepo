CREATE TABLE [dbo].[FragmentEquipmentInstanceAssociation] (
    [AssociationId]                           UNIQUEIDENTIFIER NOT NULL,
    [Version]                                 BIGINT           NULL,
    [FragmentDisplayDmcDisplayHierarchyDmcId] NVARCHAR (255)   NULL,
    [EquipmentInstanceEquipmentId]            UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([AssociationId] ASC),
    CONSTRAINT [FragmentEquipmentInstanceAssociation_DisplayDmc_Relation1] FOREIGN KEY ([FragmentDisplayDmcDisplayHierarchyDmcId]) REFERENCES [dbo].[DisplayDmc] ([DisplayDmcDisplayHierarchyDmcId]) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT [FragmentEquipmentInstanceAssociation_Equipment_Relation1] FOREIGN KEY ([EquipmentInstanceEquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId]) ON DELETE SET NULL ON UPDATE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [NC_FragmentEquipmentInstanceAssociation_FragmentDisplayDmcDisplayHierarchyDmcId]
    ON [dbo].[FragmentEquipmentInstanceAssociation]([FragmentDisplayDmcDisplayHierarchyDmcId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_FragmentEquipmentInstanceAssociation_EquipmentInstanceEquipmentId]
    ON [dbo].[FragmentEquipmentInstanceAssociation]([EquipmentInstanceEquipmentId] ASC);

