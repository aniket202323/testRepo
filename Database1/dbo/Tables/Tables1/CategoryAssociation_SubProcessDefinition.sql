CREATE TABLE [dbo].[CategoryAssociation_SubProcessDefinition] (
    [Version]                      BIGINT           NULL,
    [SubProcessDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [SubProcessDefinitionRevision] BIGINT           NOT NULL,
    [CategoryDefinitionId]         UNIQUEIDENTIFIER NOT NULL,
    [CategoryDefinitionRevision]   BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([SubProcessDefinitionId] ASC, [SubProcessDefinitionRevision] ASC, [CategoryDefinitionId] ASC, [CategoryDefinitionRevision] ASC),
    CONSTRAINT [CategoryAssociation_SubProcessDefinition_CategoryDefinition_Relation1] FOREIGN KEY ([CategoryDefinitionId], [CategoryDefinitionRevision]) REFERENCES [dbo].[CategoryDefinition] ([CategoryDefinitionId], [CategoryDefinitionRevision]),
    CONSTRAINT [CategoryAssociation_SubProcessDefinition_SubProcessDefinition_Relation1] FOREIGN KEY ([SubProcessDefinitionId], [SubProcessDefinitionRevision]) REFERENCES [dbo].[SubProcessDefinition] ([SubProcessDefinitionId], [SubProcessDefinitionRevision])
);


GO
ALTER TABLE [dbo].[CategoryAssociation_SubProcessDefinition] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_CategoryAssociation_SubProcessDefinition_CategoryDefinitionId_CategoryDefinitionRevision]
    ON [dbo].[CategoryAssociation_SubProcessDefinition]([CategoryDefinitionId] ASC, [CategoryDefinitionRevision] ASC);

