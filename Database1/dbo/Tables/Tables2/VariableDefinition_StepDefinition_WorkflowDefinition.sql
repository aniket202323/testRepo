CREATE TABLE [dbo].[VariableDefinition_StepDefinition_WorkflowDefinition] (
    [VariableDefinitionId]       NVARCHAR (64)    NOT NULL,
    [DataType]                   INT              NULL,
    [Description]                NVARCHAR (255)   NULL,
    [DisplayName]                NVARCHAR (50)    NULL,
    [Version]                    BIGINT           NULL,
    [WorkflowDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowDefinitionRevision] BIGINT           NOT NULL,
    [StepDefinitionId]           NVARCHAR (64)    NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowDefinitionId] ASC, [WorkflowDefinitionRevision] ASC, [StepDefinitionId] ASC, [VariableDefinitionId] ASC),
    CONSTRAINT [VariableDefinition_StepDefinition_WorkflowDefinition_StepDefinition_WorkflowDefinition_Relation1] FOREIGN KEY ([WorkflowDefinitionId], [WorkflowDefinitionRevision], [StepDefinitionId]) REFERENCES [dbo].[StepDefinition_WorkflowDefinition] ([WorkflowDefinitionId], [WorkflowDefinitionRevision], [StepDefinitionId])
);


GO
ALTER TABLE [dbo].[VariableDefinition_StepDefinition_WorkflowDefinition] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);

