CREATE TABLE [dbo].[VariableDefinition_StepDefinition_WorkflowSchedule] (
    [VariableDefinitionId]     NVARCHAR (64)    NOT NULL,
    [DataType]                 INT              NULL,
    [Description]              NVARCHAR (255)   NULL,
    [DisplayName]              NVARCHAR (50)    NULL,
    [Version]                  BIGINT           NULL,
    [WorkflowScheduleId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowScheduleRevision] BIGINT           NOT NULL,
    [StepDefinitionId]         NVARCHAR (64)    NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowScheduleId] ASC, [WorkflowScheduleRevision] ASC, [StepDefinitionId] ASC, [VariableDefinitionId] ASC),
    CONSTRAINT [VariableDefinition_StepDefinition_WorkflowSchedule_StepDefinition_WorkflowSchedule_Relation1] FOREIGN KEY ([WorkflowScheduleId], [WorkflowScheduleRevision], [StepDefinitionId]) REFERENCES [dbo].[StepDefinition_WorkflowSchedule] ([WorkflowScheduleId], [WorkflowScheduleRevision], [StepDefinitionId])
);

