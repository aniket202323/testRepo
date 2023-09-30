CREATE TABLE [dbo].[EquipmentClass] (
    [EquipmentClassName] NVARCHAR (200)   NOT NULL,
    [Id]                 UNIQUEIDENTIFIER NULL,
    [Description]        NVARCHAR (255)   NULL,
    [Private]            BIT              NULL,
    [Version]            BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([EquipmentClassName] ASC)
);


GO
ALTER TABLE [dbo].[EquipmentClass] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_EquipmentClass_Id]
    ON [dbo].[EquipmentClass]([Id] ASC);

