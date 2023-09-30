CREATE TABLE [dbo].[VariableDefinition_WorkflowDefinition] (
    [VariableDefinitionId]       NVARCHAR (64)    NOT NULL,
    [DataType]                   INT              NULL,
    [Description]                NVARCHAR (255)   NULL,
    [DisplayName]                NVARCHAR (50)    NULL,
    [Version]                    BIGINT           NULL,
    [WorkflowDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowDefinitionRevision] BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowDefinitionId] ASC, [WorkflowDefinitionRevision] ASC, [VariableDefinitionId] ASC),
    CONSTRAINT [VariableDefinition_WorkflowDefinition_WorkflowDefinition_Relation1] FOREIGN KEY ([WorkflowDefinitionId], [WorkflowDefinitionRevision]) REFERENCES [dbo].[WorkflowDefinition] ([WorkflowDefinitionId], [WorkflowDefinitionRevision])
);


GO
ALTER TABLE [dbo].[VariableDefinition_WorkflowDefinition] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);

