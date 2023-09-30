CREATE TABLE [dbo].[EquipmentHistorianLink] (
    [EquipmentId]           UNIQUEIDENTIFIER NOT NULL,
    [EquipmentPropertyName] NVARCHAR (255)   NOT NULL,
    [HistorianTagId]        UNIQUEIDENTIFIER NOT NULL,
    [LinkDisplayName]       NVARCHAR (1000)  NULL,
    CONSTRAINT [PK_EquipmentHistorianLink] PRIMARY KEY CLUSTERED ([EquipmentId] ASC, [EquipmentPropertyName] ASC),
    CONSTRAINT [FK_EquipmentHistorianLink_ToProperty] FOREIGN KEY ([EquipmentId], [EquipmentPropertyName]) REFERENCES [dbo].[Property_Equipment_EquipmentClass] ([EquipmentId], [Name]) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT [FK_EquipmentHistorianLink_ToTag] FOREIGN KEY ([HistorianTagId]) REFERENCES [dbo].[Historian_Tag] ([Id])
);

