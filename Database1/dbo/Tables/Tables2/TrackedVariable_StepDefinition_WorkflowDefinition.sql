CREATE TABLE [dbo].[TrackedVariable_StepDefinition_WorkflowDefinition] (
    [StepDefinitionId]           NVARCHAR (64)    NOT NULL,
    [VariableDefinitionId]       NVARCHAR (64)    NOT NULL,
    [Version]                    BIGINT           NULL,
    [WorkflowDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowDefinitionRevision] BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowDefinitionId] ASC, [WorkflowDefinitionRevision] ASC, [StepDefinitionId] ASC, [VariableDefinitionId] ASC),
    CONSTRAINT [TrackedVariable_StepDefinition_WorkflowDefinition_WorkflowDefinition_Relation1] FOREIGN KEY ([WorkflowDefinitionId], [WorkflowDefinitionRevision]) REFERENCES [dbo].[WorkflowDefinition] ([WorkflowDefinitionId], [WorkflowDefinitionRevision])
);


GO
ALTER TABLE [dbo].[TrackedVariable_StepDefinition_WorkflowDefinition] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);

