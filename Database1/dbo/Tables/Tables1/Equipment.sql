CREATE TABLE [dbo].[Equipment] (
    [EquipmentId]       UNIQUEIDENTIFIER NOT NULL,
    [S95Id]             NVARCHAR (50)    NULL,
    [Description]       NVARCHAR (255)   NULL,
    [Type]              NVARCHAR (255)   NULL,
    [Version]           BIGINT           NULL,
    [ParentEquipmentId] UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([EquipmentId] ASC),
    CONSTRAINT [Equipment_Equipment_Relation1] FOREIGN KEY ([ParentEquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId])
);


GO
ALTER TABLE [dbo].[Equipment] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [IX_Equipment_S95Id]
    ON [dbo].[Equipment]([S95Id] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Equipment_ParentEquipmentId_S95Id_Type]
    ON [dbo].[Equipment]([ParentEquipmentId] ASC, [S95Id] ASC, [Type] ASC);

