CREATE TABLE [dbo].[EquipmentPropertyHistory] (
    [PropertyName] NVARCHAR (255)   NOT NULL,
    [Timestamp]    DATETIME         NOT NULL,
    [Value]        SQL_VARIANT      NULL,
    [Version]      BIGINT           NULL,
    [EquipmentId]  UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([EquipmentId] ASC, [PropertyName] ASC, [Timestamp] ASC),
    CONSTRAINT [EquipmentPropertyHistory_Equipment_Relation1] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId])
);

