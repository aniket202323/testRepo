CREATE TABLE [dbo].[ExpiryDefinition_WorkflowSchedule] (
    [AbsoluteExpiryTime]       DATETIME         NULL,
    [ExpiryCondition]          IMAGE            NULL,
    [ExpiryType]               INT              NULL,
    [RelativeExpiryTime]       BIGINT           NULL,
    [Version]                  BIGINT           NULL,
    [WorkflowScheduleId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowScheduleRevision] BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowScheduleId] ASC, [WorkflowScheduleRevision] ASC),
    CONSTRAINT [ExpiryDefinition_WorkflowSchedule_WorkflowSchedule_Relation1] FOREIGN KEY ([WorkflowScheduleId], [WorkflowScheduleRevision]) REFERENCES [dbo].[WorkflowSchedule] ([WorkflowScheduleId], [WorkflowScheduleRevision])
);

