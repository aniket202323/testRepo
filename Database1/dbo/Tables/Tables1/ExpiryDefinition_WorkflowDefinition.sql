CREATE TABLE [dbo].[ExpiryDefinition_WorkflowDefinition] (
    [AbsoluteExpiryTime]         DATETIME         NULL,
    [ExpiryCondition]            IMAGE            NULL,
    [ExpiryType]                 INT              NULL,
    [RelativeExpiryTime]         BIGINT           NULL,
    [Version]                    BIGINT           NULL,
    [WorkflowDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowDefinitionRevision] BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowDefinitionId] ASC, [WorkflowDefinitionRevision] ASC),
    CONSTRAINT [ExpiryDefinition_WorkflowDefinition_WorkflowDefinition_Relation1] FOREIGN KEY ([WorkflowDefinitionId], [WorkflowDefinitionRevision]) REFERENCES [dbo].[WorkflowDefinition] ([WorkflowDefinitionId], [WorkflowDefinitionRevision])
);

