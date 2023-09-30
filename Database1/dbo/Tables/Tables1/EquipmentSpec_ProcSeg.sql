CREATE TABLE [dbo].[EquipmentSpec_ProcSeg] (
    [S95Id]                   NVARCHAR (50)    NULL,
    [QuantityUnitOfMeasure]   NVARCHAR (50)    NULL,
    [Quantity]                FLOAT (53)       NULL,
    [EquipmentSpec_ProcSegId] UNIQUEIDENTIFIER NOT NULL,
    [Description]             NVARCHAR (255)   NULL,
    [S95Type]                 NVARCHAR (50)    NULL,
    [LastModifiedTime]        DATETIME         NULL,
    [LastModifiedBy]          NVARCHAR (255)   NULL,
    [Version]                 BIGINT           NULL,
    [ProcSegId]               UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([EquipmentSpec_ProcSegId] ASC, [ProcSegId] ASC),
    CONSTRAINT [EquipmentSpec_ProcSeg_ProcSeg_Relation1] FOREIGN KEY ([ProcSegId]) REFERENCES [dbo].[ProcSeg] ([ProcSegId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_EquipmentSpec_ProcSeg_S95Id_ProcSegId]
    ON [dbo].[EquipmentSpec_ProcSeg]([S95Id] ASC, [ProcSegId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EquipmentSpec_ProcSeg_LastModifiedTime]
    ON [dbo].[EquipmentSpec_ProcSeg]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_EquipmentSpec_ProcSeg_ProcSegId]
    ON [dbo].[EquipmentSpec_ProcSeg]([ProcSegId] ASC);

