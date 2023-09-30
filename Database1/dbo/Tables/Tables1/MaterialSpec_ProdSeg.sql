CREATE TABLE [dbo].[MaterialSpec_ProdSeg] (
    [r_Use]                  NVARCHAR (255)   NULL,
    [S95Id]                  NVARCHAR (50)    NULL,
    [QuantityUnitOfMeasure]  NVARCHAR (50)    NULL,
    [Quantity]               FLOAT (53)       NULL,
    [MaterialSpec_ProdSegId] UNIQUEIDENTIFIER NOT NULL,
    [Description]            NVARCHAR (255)   NULL,
    [S95Type]                NVARCHAR (50)    NULL,
    [LastModifiedTime]       DATETIME         NULL,
    [LastModifiedBy]         NVARCHAR (255)   NULL,
    [Version]                BIGINT           NULL,
    [ProdSegId]              UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([MaterialSpec_ProdSegId] ASC, [ProdSegId] ASC),
    CONSTRAINT [MaterialSpec_ProdSeg_ProdSeg_Relation1] FOREIGN KEY ([ProdSegId]) REFERENCES [dbo].[ProdSeg] ([ProdSegId])
);


GO
CREATE NONCLUSTERED INDEX [IX_MaterialSpec_ProdSeg_S95Id]
    ON [dbo].[MaterialSpec_ProdSeg]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MaterialSpec_ProdSeg_LastModifiedTime]
    ON [dbo].[MaterialSpec_ProdSeg]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_MaterialSpec_ProdSeg_ProdSegId]
    ON [dbo].[MaterialSpec_ProdSeg]([ProdSegId] ASC);

