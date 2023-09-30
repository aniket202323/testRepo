CREATE TABLE [dbo].[CategoryAssociation_CompletionCodeDefinition] (
    [Version]                          BIGINT           NULL,
    [CompletionCodeDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [CompletionCodeDefinitionRevision] BIGINT           NOT NULL,
    [CategoryDefinitionId]             UNIQUEIDENTIFIER NOT NULL,
    [CategoryDefinitionRevision]       BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([CompletionCodeDefinitionId] ASC, [CompletionCodeDefinitionRevision] ASC, [CategoryDefinitionId] ASC, [CategoryDefinitionRevision] ASC),
    CONSTRAINT [CategoryAssociation_CompletionCodeDefinition_CategoryDefinition_Relation1] FOREIGN KEY ([CategoryDefinitionId], [CategoryDefinitionRevision]) REFERENCES [dbo].[CategoryDefinition] ([CategoryDefinitionId], [CategoryDefinitionRevision]),
    CONSTRAINT [CategoryAssociation_CompletionCodeDefinition_CompletionCodeDefinition_Relation1] FOREIGN KEY ([CompletionCodeDefinitionId], [CompletionCodeDefinitionRevision]) REFERENCES [dbo].[CompletionCodeDefinition] ([CompletionCodeDefinitionId], [CompletionCodeDefinitionRevision])
);


GO
ALTER TABLE [dbo].[CategoryAssociation_CompletionCodeDefinition] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_CategoryAssociation_CompletionCodeDefinition_CategoryDefinitionId_CategoryDefinitionRevision]
    ON [dbo].[CategoryAssociation_CompletionCodeDefinition]([CategoryDefinitionId] ASC, [CategoryDefinitionRevision] ASC);

