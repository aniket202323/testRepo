CREATE TABLE [dbo].[LinkedDocument_StepDefinition_WorkflowDefinition] (
    [DocumentId]                 UNIQUEIDENTIFIER NOT NULL,
    [DocumentName]               NVARCHAR (50)    NULL,
    [DocumentUrlUnc]             NVARCHAR (255)   NULL,
    [Version]                    BIGINT           NULL,
    [WorkflowDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowDefinitionRevision] BIGINT           NOT NULL,
    [StepDefinitionId]           NVARCHAR (64)    NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowDefinitionId] ASC, [WorkflowDefinitionRevision] ASC, [StepDefinitionId] ASC, [DocumentId] ASC),
    CONSTRAINT [LinkedDocument_StepDefinition_WorkflowDefinition_StepDefinition_WorkflowDefinition_Relation1] FOREIGN KEY ([WorkflowDefinitionId], [WorkflowDefinitionRevision], [StepDefinitionId]) REFERENCES [dbo].[StepDefinition_WorkflowDefinition] ([WorkflowDefinitionId], [WorkflowDefinitionRevision], [StepDefinitionId])
);

