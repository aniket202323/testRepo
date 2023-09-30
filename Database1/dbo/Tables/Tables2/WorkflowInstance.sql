CREATE TABLE [dbo].[WorkflowInstance] (
    [InputParameters]            IMAGE            NULL,
    [InstanceId]                 UNIQUEIDENTIFIER NOT NULL,
    [IsTest]                     BIT              NULL,
    [IsTrackingEnabled]          BIT              NULL,
    [StartedBy]                  INT              NULL,
    [StartTime]                  DATETIME         NULL,
    [State]                      NVARCHAR (255)   NULL,
    [TerminateOnRecover]         BIT              NULL,
    [TrackingLevel]              NVARCHAR (255)   NULL,
    [Version]                    BIGINT           NULL,
    [WorkflowDefinitionId]       UNIQUEIDENTIFIER NULL,
    [WorkflowDefinitionRevision] BIGINT           NULL,
    [WorkflowScheduleId]         UNIQUEIDENTIFIER NULL,
    [WorkflowScheduleRevision]   BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([InstanceId] ASC),
    CONSTRAINT [WorkflowInstance_WorkflowDefinition_Relation1] FOREIGN KEY ([WorkflowDefinitionId], [WorkflowDefinitionRevision]) REFERENCES [dbo].[WorkflowDefinition] ([WorkflowDefinitionId], [WorkflowDefinitionRevision]),
    CONSTRAINT [WorkflowInstance_WorkflowSchedule_Relation1] FOREIGN KEY ([WorkflowScheduleId], [WorkflowScheduleRevision]) REFERENCES [dbo].[WorkflowSchedule] ([WorkflowScheduleId], [WorkflowScheduleRevision])
);


GO
CREATE NONCLUSTERED INDEX [NC_WorkflowInstance_WorkflowDefinitionId_WorkflowDefinitionRevision]
    ON [dbo].[WorkflowInstance]([WorkflowDefinitionId] ASC, [WorkflowDefinitionRevision] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_WorkflowInstance_WorkflowScheduleId_WorkflowScheduleRevision]
    ON [dbo].[WorkflowInstance]([WorkflowScheduleId] ASC, [WorkflowScheduleRevision] ASC);

