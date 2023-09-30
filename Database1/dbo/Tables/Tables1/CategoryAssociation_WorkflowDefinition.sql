CREATE TABLE [dbo].[CategoryAssociation_WorkflowDefinition] (
    [Version]                    BIGINT           NULL,
    [WorkflowDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowDefinitionRevision] BIGINT           NOT NULL,
    [CategoryDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [CategoryDefinitionRevision] BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowDefinitionId] ASC, [WorkflowDefinitionRevision] ASC, [CategoryDefinitionId] ASC, [CategoryDefinitionRevision] ASC),
    CONSTRAINT [CategoryAssociation_WorkflowDefinition_CategoryDefinition_Relation1] FOREIGN KEY ([CategoryDefinitionId], [CategoryDefinitionRevision]) REFERENCES [dbo].[CategoryDefinition] ([CategoryDefinitionId], [CategoryDefinitionRevision]),
    CONSTRAINT [CategoryAssociation_WorkflowDefinition_WorkflowDefinition_Relation1] FOREIGN KEY ([WorkflowDefinitionId], [WorkflowDefinitionRevision]) REFERENCES [dbo].[WorkflowDefinition] ([WorkflowDefinitionId], [WorkflowDefinitionRevision])
);


GO
ALTER TABLE [dbo].[CategoryAssociation_WorkflowDefinition] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_CategoryAssociation_WorkflowDefinition_CategoryDefinitionId_CategoryDefinitionRevision]
    ON [dbo].[CategoryAssociation_WorkflowDefinition]([CategoryDefinitionId] ASC, [CategoryDefinitionRevision] ASC);

