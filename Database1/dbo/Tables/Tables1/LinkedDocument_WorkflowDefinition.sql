CREATE TABLE [dbo].[LinkedDocument_WorkflowDefinition] (
    [DocumentId]                 UNIQUEIDENTIFIER NOT NULL,
    [DocumentName]               NVARCHAR (50)    NULL,
    [DocumentUrlUnc]             NVARCHAR (255)   NULL,
    [Version]                    BIGINT           NULL,
    [WorkflowDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowDefinitionRevision] BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowDefinitionId] ASC, [WorkflowDefinitionRevision] ASC, [DocumentId] ASC),
    CONSTRAINT [LinkedDocument_WorkflowDefinition_WorkflowDefinition_Relation1] FOREIGN KEY ([WorkflowDefinitionId], [WorkflowDefinitionRevision]) REFERENCES [dbo].[WorkflowDefinition] ([WorkflowDefinitionId], [WorkflowDefinitionRevision])
);

