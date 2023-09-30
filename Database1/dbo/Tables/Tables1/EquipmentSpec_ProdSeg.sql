CREATE TABLE [dbo].[EquipmentSpec_ProdSeg] (
    [S95Id]                   NVARCHAR (50)    NULL,
    [QuantityUnitOfMeasure]   NVARCHAR (50)    NULL,
    [Quantity]                FLOAT (53)       NULL,
    [EquipmentSpec_ProdSegId] UNIQUEIDENTIFIER NOT NULL,
    [Description]             NVARCHAR (255)   NULL,
    [S95Type]                 NVARCHAR (50)    NULL,
    [LastModifiedTime]        DATETIME         NULL,
    [LastModifiedBy]          NVARCHAR (255)   NULL,
    [Version]                 BIGINT           NULL,
    [ProdSegId]               UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([EquipmentSpec_ProdSegId] ASC, [ProdSegId] ASC),
    CONSTRAINT [EquipmentSpec_ProdSeg_ProdSeg_Relation1] FOREIGN KEY ([ProdSegId]) REFERENCES [dbo].[ProdSeg] ([ProdSegId])
);


GO
CREATE NONCLUSTERED INDEX [IX_EquipmentSpec_ProdSeg_S95Id]
    ON [dbo].[EquipmentSpec_ProdSeg]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EquipmentSpec_ProdSeg_LastModifiedTime]
    ON [dbo].[EquipmentSpec_ProdSeg]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_EquipmentSpec_ProdSeg_ProdSegId]
    ON [dbo].[EquipmentSpec_ProdSeg]([ProdSegId] ASC);

