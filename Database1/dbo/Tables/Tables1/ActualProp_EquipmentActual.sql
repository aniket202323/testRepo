CREATE TABLE [dbo].[ActualProp_EquipmentActual] (
    [Name]              NVARCHAR (255)   NOT NULL,
    [Description]       NVARCHAR (255)   NULL,
    [DataType]          INT              NULL,
    [UnitOfMeasure]     NVARCHAR (255)   NULL,
    [TimeStamp]         DATETIME         NULL,
    [Value]             SQL_VARIANT      NULL,
    [Version]           BIGINT           NULL,
    [EquipmentActualId] UNIQUEIDENTIFIER NOT NULL,
    [ItemId]            UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([EquipmentActualId] ASC, [Name] ASC),
    CONSTRAINT [ActualProp_EquipmentActual_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [ActualProp_EquipmentActual_EquipmentActual_Relation1] FOREIGN KEY ([EquipmentActualId]) REFERENCES [dbo].[EquipmentActual] ([EquipmentActualId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ActualProp_EquipmentActual_ItemId]
    ON [dbo].[ActualProp_EquipmentActual]([ItemId] ASC);

