CREATE TABLE [dbo].[ProductSegmentLevel] (
    [Id]                     UNIQUEIDENTIFIER NOT NULL,
    [ParentAssociationName]  NVARCHAR (255)   NULL,
    [Level]                  INT              NULL,
    [ParentId]               UNIQUEIDENTIFIER NULL,
    [Version]                BIGINT           NULL,
    [WorkDefinitionId]       UNIQUEIDENTIFIER NULL,
    [ProdSegId]              UNIQUEIDENTIFIER NULL,
    [ParentSegmentProdSegId] UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [ProductSegmentLevel_ProdSeg_Relation1] FOREIGN KEY ([ProdSegId]) REFERENCES [dbo].[ProdSeg] ([ProdSegId]),
    CONSTRAINT [ProductSegmentLevel_ProdSeg_Relation2] FOREIGN KEY ([ParentSegmentProdSegId]) REFERENCES [dbo].[ProdSeg] ([ProdSegId]),
    CONSTRAINT [ProductSegmentLevel_WorkDefinition_Relation1] FOREIGN KEY ([WorkDefinitionId]) REFERENCES [dbo].[WorkDefinition] ([WorkDefinitionId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ProductSegmentLevel_WorkDefinitionId]
    ON [dbo].[ProductSegmentLevel]([WorkDefinitionId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_ProductSegmentLevel_ProdSegId]
    ON [dbo].[ProductSegmentLevel]([ProdSegId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_ProductSegmentLevel_ParentSegmentProdSegId]
    ON [dbo].[ProductSegmentLevel]([ParentSegmentProdSegId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_ProductSegmentLevel_Level_ParentId]
    ON [dbo].[ProductSegmentLevel]([Level] ASC, [ParentId] ASC);

