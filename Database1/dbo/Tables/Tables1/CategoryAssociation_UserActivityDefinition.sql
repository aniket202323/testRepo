CREATE TABLE [dbo].[CategoryAssociation_UserActivityDefinition] (
    [Version]                        BIGINT           NULL,
    [UserActivityDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [UserActivityDefinitionRevision] BIGINT           NOT NULL,
    [CategoryDefinitionId]           UNIQUEIDENTIFIER NOT NULL,
    [CategoryDefinitionRevision]     BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([UserActivityDefinitionId] ASC, [UserActivityDefinitionRevision] ASC, [CategoryDefinitionId] ASC, [CategoryDefinitionRevision] ASC),
    CONSTRAINT [CategoryAssociation_UserActivityDefinition_CategoryDefinition_Relation1] FOREIGN KEY ([CategoryDefinitionId], [CategoryDefinitionRevision]) REFERENCES [dbo].[CategoryDefinition] ([CategoryDefinitionId], [CategoryDefinitionRevision]),
    CONSTRAINT [CategoryAssociation_UserActivityDefinition_UserActivityDefinition_Relation1] FOREIGN KEY ([UserActivityDefinitionId], [UserActivityDefinitionRevision]) REFERENCES [dbo].[UserActivityDefinition] ([UserActivityDefinitionId], [UserActivityDefinitionRevision])
);


GO
CREATE NONCLUSTERED INDEX [NC_CategoryAssociation_UserActivityDefinition_CategoryDefinitionId_CategoryDefinitionRevision]
    ON [dbo].[CategoryAssociation_UserActivityDefinition]([CategoryDefinitionId] ASC, [CategoryDefinitionRevision] ASC);

