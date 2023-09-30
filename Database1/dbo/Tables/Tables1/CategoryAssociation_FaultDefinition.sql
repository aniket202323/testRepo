CREATE TABLE [dbo].[CategoryAssociation_FaultDefinition] (
    [Version]                    BIGINT           NULL,
    [FaultDefinitionId]          UNIQUEIDENTIFIER NOT NULL,
    [FaultDefinitionRevision]    BIGINT           NOT NULL,
    [CategoryDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [CategoryDefinitionRevision] BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([FaultDefinitionId] ASC, [FaultDefinitionRevision] ASC, [CategoryDefinitionId] ASC, [CategoryDefinitionRevision] ASC),
    CONSTRAINT [CategoryAssociation_FaultDefinition_CategoryDefinition_Relation1] FOREIGN KEY ([CategoryDefinitionId], [CategoryDefinitionRevision]) REFERENCES [dbo].[CategoryDefinition] ([CategoryDefinitionId], [CategoryDefinitionRevision]),
    CONSTRAINT [CategoryAssociation_FaultDefinition_FaultDefinition_Relation1] FOREIGN KEY ([FaultDefinitionId], [FaultDefinitionRevision]) REFERENCES [dbo].[FaultDefinition] ([FaultDefinitionId], [FaultDefinitionRevision])
);


GO
CREATE NONCLUSTERED INDEX [NC_CategoryAssociation_FaultDefinition_CategoryDefinitionId_CategoryDefinitionRevision]
    ON [dbo].[CategoryAssociation_FaultDefinition]([CategoryDefinitionId] ASC, [CategoryDefinitionRevision] ASC);

