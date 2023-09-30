CREATE TABLE [dbo].[WorkDefinition] (
    [ProductionRule]         NVARCHAR (255)   NULL,
    [PublishedDate]          DATETIME         NULL,
    [UserVersion]            NVARCHAR (255)   NULL,
    [DurationUnitOfMeasure]  NVARCHAR (255)   NULL,
    [Enabled]                BIT              NULL,
    [WorkType]               NVARCHAR (25)    NULL,
    [WorkDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [S95Id]                  NVARCHAR (50)    NULL,
    [Description]            NVARCHAR (255)   NULL,
    [S95Type]                NVARCHAR (50)    NULL,
    [LastModifiedTime]       DATETIME         NULL,
    [LastModifiedBy]         NVARCHAR (255)   NULL,
    [Version]                BIGINT           NULL,
    [MasterSegmentProdSegId] UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([WorkDefinitionId] ASC),
    CONSTRAINT [WorkDefinition_ProdSeg_Relation1] FOREIGN KEY ([MasterSegmentProdSegId]) REFERENCES [dbo].[ProdSeg] ([ProdSegId])
);


GO
CREATE NONCLUSTERED INDEX [IX_WorkDefinition_LastModifiedTime]
    ON [dbo].[WorkDefinition]([LastModifiedTime] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_WorkDefinition_S95Id]
    ON [dbo].[WorkDefinition]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_WorkDefinition_MasterSegmentProdSegId]
    ON [dbo].[WorkDefinition]([MasterSegmentProdSegId] ASC);

