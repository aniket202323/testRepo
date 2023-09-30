CREATE TABLE [dbo].[WorkflowScheduleParameterValue] (
    [Name]                     NVARCHAR (255)   NOT NULL,
    [Value]                    IMAGE            NULL,
    [ScheduleParameterKind]    INT              NULL,
    [Version]                  BIGINT           NULL,
    [WorkflowScheduleId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowScheduleRevision] BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowScheduleId] ASC, [WorkflowScheduleRevision] ASC, [Name] ASC),
    CONSTRAINT [WorkflowScheduleParameterValue_WorkflowSchedule_Relation1] FOREIGN KEY ([WorkflowScheduleId], [WorkflowScheduleRevision]) REFERENCES [dbo].[WorkflowSchedule] ([WorkflowScheduleId], [WorkflowScheduleRevision])
);

