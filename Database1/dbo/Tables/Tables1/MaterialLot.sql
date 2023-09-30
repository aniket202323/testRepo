CREATE TABLE [dbo].[MaterialLot] (
    [MaterialLotId]         UNIQUEIDENTIFIER NOT NULL,
    [S95Id]                 NVARCHAR (50)    NULL,
    [Description]           NVARCHAR (255)   NULL,
    [Status]                NVARCHAR (255)   NULL,
    [QuantityUnitOfMeasure] NVARCHAR (50)    NULL,
    [Quantity]              FLOAT (53)       NULL,
    [AssemblyType]          NVARCHAR (50)    NULL,
    [AssemblyRelationship]  NVARCHAR (50)    NULL,
    [IsClosed]              BIT              NULL,
    [ClosedTime]            DATETIME         NULL,
    [LastModifiedTime]      DATETIME         NULL,
    [Version]               BIGINT           NULL,
    [EquipmentId]           UNIQUEIDENTIFIER NULL,
    [MaterialDefinitionId]  UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([MaterialLotId] ASC),
    CONSTRAINT [MaterialLot_Equipment_Relation1] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId]),
    CONSTRAINT [MaterialLot_MaterialDefinition_Relation1] FOREIGN KEY ([MaterialDefinitionId]) REFERENCES [dbo].[MaterialDefinition] ([MaterialDefinitionId])
);


GO
CREATE NONCLUSTERED INDEX [NC_MaterialLot_EquipmentId]
    ON [dbo].[MaterialLot]([EquipmentId] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_MaterialLot_MaterialDefinitionId_S95Id]
    ON [dbo].[MaterialLot]([MaterialDefinitionId] ASC, [S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MaterialLot_LastModifiedTime]
    ON [dbo].[MaterialLot]([LastModifiedTime] ASC)
    INCLUDE([MaterialLotId], [S95Id], [Description], [Status], [QuantityUnitOfMeasure], [Quantity], [AssemblyType], [AssemblyRelationship], [IsClosed], [ClosedTime], [Version], [EquipmentId], [MaterialDefinitionId]);

