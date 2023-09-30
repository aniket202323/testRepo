CREATE TABLE [dbo].[MaterialSublot] (
    [MaterialSublotId]             UNIQUEIDENTIFIER NOT NULL,
    [S95Id]                        NVARCHAR (50)    NULL,
    [Description]                  NVARCHAR (255)   NULL,
    [Status]                       NVARCHAR (255)   NULL,
    [QuantityUnitOfMeasure]        NVARCHAR (50)    NULL,
    [Quantity]                     FLOAT (53)       NULL,
    [LastModifiedTime]             DATETIME         NULL,
    [Version]                      BIGINT           NULL,
    [EquipmentId]                  UNIQUEIDENTIFIER NULL,
    [MaterialLotId]                UNIQUEIDENTIFIER NULL,
    [ParentSublotMaterialSublotId] UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([MaterialSublotId] ASC),
    CONSTRAINT [MaterialSublot_Equipment_Relation1] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId]),
    CONSTRAINT [MaterialSublot_MaterialLot_Relation1] FOREIGN KEY ([MaterialLotId]) REFERENCES [dbo].[MaterialLot] ([MaterialLotId]),
    CONSTRAINT [MaterialSublot_MaterialSublot_Relation1] FOREIGN KEY ([ParentSublotMaterialSublotId]) REFERENCES [dbo].[MaterialSublot] ([MaterialSublotId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_MaterialSublot_S95Id]
    ON [dbo].[MaterialSublot]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_MaterialSublot_EquipmentId]
    ON [dbo].[MaterialSublot]([EquipmentId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_MaterialSublot_MaterialLotId]
    ON [dbo].[MaterialSublot]([MaterialLotId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_MaterialSublot_ParentSublotMaterialSublotId]
    ON [dbo].[MaterialSublot]([ParentSublotMaterialSublotId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MaterialSublot_LastModifiedTime]
    ON [dbo].[MaterialSublot]([LastModifiedTime] ASC)
    INCLUDE([MaterialSublotId], [S95Id], [Description], [Status], [QuantityUnitOfMeasure], [Quantity], [Version], [EquipmentId], [MaterialLotId], [ParentSublotMaterialSublotId]);

