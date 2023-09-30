CREATE TABLE [dbo].[SegmentSpecification] (
    [S95Id]                  NVARCHAR (50)    NULL,
    [r_Order]                INT              NULL,
    [SegmentSpecificationId] UNIQUEIDENTIFIER NOT NULL,
    [Description]            NVARCHAR (255)   NULL,
    [S95Type]                NVARCHAR (50)    NULL,
    [LastModifiedTime]       DATETIME         NULL,
    [LastModifiedBy]         NVARCHAR (255)   NULL,
    [Version]                BIGINT           NULL,
    [WorkDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [ProdSegId]              UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([SegmentSpecificationId] ASC, [WorkDefinitionId] ASC, [ProdSegId] ASC),
    CONSTRAINT [SegmentSpecification_ProdSeg_Relation1] FOREIGN KEY ([ProdSegId]) REFERENCES [dbo].[ProdSeg] ([ProdSegId]),
    CONSTRAINT [SegmentSpecification_WorkDefinition_Relation1] FOREIGN KEY ([WorkDefinitionId]) REFERENCES [dbo].[WorkDefinition] ([WorkDefinitionId])
);


GO
CREATE NONCLUSTERED INDEX [IX_SegmentSpecification_S95Id]
    ON [dbo].[SegmentSpecification]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SegmentSpecification_LastModifiedTime]
    ON [dbo].[SegmentSpecification]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SegmentSpecification_WorkDefinitionId]
    ON [dbo].[SegmentSpecification]([WorkDefinitionId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SegmentSpecification_ProdSegId]
    ON [dbo].[SegmentSpecification]([ProdSegId] ASC);

