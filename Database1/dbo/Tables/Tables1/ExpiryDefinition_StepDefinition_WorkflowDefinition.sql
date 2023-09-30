CREATE TABLE [dbo].[ExpiryDefinition_StepDefinition_WorkflowDefinition] (
    [AbsoluteExpiryTime]         DATETIME         NULL,
    [ExpiryCondition]            IMAGE            NULL,
    [ExpiryType]                 INT              NULL,
    [RelativeExpiryTime]         BIGINT           NULL,
    [Version]                    BIGINT           NULL,
    [WorkflowDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowDefinitionRevision] BIGINT           NOT NULL,
    [StepDefinitionId]           NVARCHAR (64)    NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowDefinitionId] ASC, [WorkflowDefinitionRevision] ASC, [StepDefinitionId] ASC),
    CONSTRAINT [ExpiryDefinition_StepDefinition_WorkflowDefinition_StepDefinition_WorkflowDefinition_Relation1] FOREIGN KEY ([WorkflowDefinitionId], [WorkflowDefinitionRevision], [StepDefinitionId]) REFERENCES [dbo].[StepDefinition_WorkflowDefinition] ([WorkflowDefinitionId], [WorkflowDefinitionRevision], [StepDefinitionId])
);

