CREATE TABLE [dbo].[MaterialSpec_ProcSeg] (
    [r_Use]                  NVARCHAR (255)   NULL,
    [S95Id]                  NVARCHAR (50)    NULL,
    [QuantityUnitOfMeasure]  NVARCHAR (50)    NULL,
    [Quantity]               FLOAT (53)       NULL,
    [MaterialSpec_ProcSegId] UNIQUEIDENTIFIER NOT NULL,
    [Description]            NVARCHAR (255)   NULL,
    [S95Type]                NVARCHAR (50)    NULL,
    [LastModifiedTime]       DATETIME         NULL,
    [LastModifiedBy]         NVARCHAR (255)   NULL,
    [Version]                BIGINT           NULL,
    [ProcSegId]              UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([MaterialSpec_ProcSegId] ASC, [ProcSegId] ASC),
    CONSTRAINT [MaterialSpec_ProcSeg_ProcSeg_Relation1] FOREIGN KEY ([ProcSegId]) REFERENCES [dbo].[ProcSeg] ([ProcSegId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_MaterialSpec_ProcSeg_S95Id_ProcSegId]
    ON [dbo].[MaterialSpec_ProcSeg]([S95Id] ASC, [ProcSegId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MaterialSpec_ProcSeg_LastModifiedTime]
    ON [dbo].[MaterialSpec_ProcSeg]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_MaterialSpec_ProcSeg_ProcSegId]
    ON [dbo].[MaterialSpec_ProcSeg]([ProcSegId] ASC);

