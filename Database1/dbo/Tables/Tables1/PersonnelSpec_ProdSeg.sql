CREATE TABLE [dbo].[PersonnelSpec_ProdSeg] (
    [S95Id]                   NVARCHAR (50)    NULL,
    [QuantityUnitOfMeasure]   NVARCHAR (50)    NULL,
    [Quantity]                FLOAT (53)       NULL,
    [PersonnelSpec_ProdSegId] UNIQUEIDENTIFIER NOT NULL,
    [Description]             NVARCHAR (255)   NULL,
    [S95Type]                 NVARCHAR (50)    NULL,
    [LastModifiedTime]        DATETIME         NULL,
    [LastModifiedBy]          NVARCHAR (255)   NULL,
    [Version]                 BIGINT           NULL,
    [ProdSegId]               UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([PersonnelSpec_ProdSegId] ASC, [ProdSegId] ASC),
    CONSTRAINT [PersonnelSpec_ProdSeg_ProdSeg_Relation1] FOREIGN KEY ([ProdSegId]) REFERENCES [dbo].[ProdSeg] ([ProdSegId])
);


GO
CREATE NONCLUSTERED INDEX [IX_PersonnelSpec_ProdSeg_S95Id]
    ON [dbo].[PersonnelSpec_ProdSeg]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PersonnelSpec_ProdSeg_LastModifiedTime]
    ON [dbo].[PersonnelSpec_ProdSeg]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PersonnelSpec_ProdSeg_ProdSegId]
    ON [dbo].[PersonnelSpec_ProdSeg]([ProdSegId] ASC);

