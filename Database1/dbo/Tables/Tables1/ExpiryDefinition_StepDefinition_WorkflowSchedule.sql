CREATE TABLE [dbo].[ExpiryDefinition_StepDefinition_WorkflowSchedule] (
    [AbsoluteExpiryTime]       DATETIME         NULL,
    [ExpiryCondition]          IMAGE            NULL,
    [ExpiryType]               INT              NULL,
    [RelativeExpiryTime]       BIGINT           NULL,
    [Version]                  BIGINT           NULL,
    [WorkflowScheduleId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowScheduleRevision] BIGINT           NOT NULL,
    [StepDefinitionId]         NVARCHAR (64)    NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowScheduleId] ASC, [WorkflowScheduleRevision] ASC, [StepDefinitionId] ASC),
    CONSTRAINT [ExpiryDefinition_StepDefinition_WorkflowSchedule_StepDefinition_WorkflowSchedule_Relation1] FOREIGN KEY ([WorkflowScheduleId], [WorkflowScheduleRevision], [StepDefinitionId]) REFERENCES [dbo].[StepDefinition_WorkflowSchedule] ([WorkflowScheduleId], [WorkflowScheduleRevision], [StepDefinitionId])
);

