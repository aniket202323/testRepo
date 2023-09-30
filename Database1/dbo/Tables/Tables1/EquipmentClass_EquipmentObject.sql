CREATE TABLE [dbo].[EquipmentClass_EquipmentObject] (
    [ClassOrder]         INT              NULL,
    [Version]            BIGINT           NULL,
    [EquipmentClassName] NVARCHAR (200)   NOT NULL,
    [EquipmentId]        UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([EquipmentClassName] ASC, [EquipmentId] ASC),
    CONSTRAINT [EquipmentClass_EquipmentObject_Equipment_Relation1] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId]),
    CONSTRAINT [EquipmentClass_EquipmentObject_EquipmentClass_Relation1] FOREIGN KEY ([EquipmentClassName]) REFERENCES [dbo].[EquipmentClass] ([EquipmentClassName]) ON UPDATE CASCADE
);


GO
ALTER TABLE [dbo].[EquipmentClass_EquipmentObject] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_EquipmentClass_EquipmentObject_EquipmentId]
    ON [dbo].[EquipmentClass_EquipmentObject]([EquipmentId] ASC);

