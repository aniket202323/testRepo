CREATE TABLE [dbo].[StepDefinition_WorkflowSchedule] (
    [StepDefinitionId]             NVARCHAR (64)    NOT NULL,
    [AssignedLocationAddress]      NVARCHAR (1024)  NULL,
    [AssignedPersonnelAddress]     NVARCHAR (1024)  NULL,
    [Description]                  NVARCHAR (255)   NULL,
    [DisplayName]                  NVARCHAR (50)    NULL,
    [r_Order]                      INT              NULL,
    [LinkedDocumentCount]          INT              NULL,
    [Version]                      BIGINT           NULL,
    [WorkflowScheduleId]           UNIQUEIDENTIFIER NOT NULL,
    [WorkflowScheduleRevision]     BIGINT           NOT NULL,
    [SubProcessDefinitionId]       UNIQUEIDENTIFIER NULL,
    [SubProcessDefinitionRevision] BIGINT           NULL,
    [WorkInstructionsId]           UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([WorkflowScheduleId] ASC, [WorkflowScheduleRevision] ASC, [StepDefinitionId] ASC),
    CONSTRAINT [StepDefinition_WorkflowSchedule_SubProcessDefinition_Relation1] FOREIGN KEY ([SubProcessDefinitionId], [SubProcessDefinitionRevision]) REFERENCES [dbo].[SubProcessDefinition] ([SubProcessDefinitionId], [SubProcessDefinitionRevision]),
    CONSTRAINT [StepDefinition_WorkflowSchedule_WorkflowSchedule_Relation1] FOREIGN KEY ([WorkflowScheduleId], [WorkflowScheduleRevision]) REFERENCES [dbo].[WorkflowSchedule] ([WorkflowScheduleId], [WorkflowScheduleRevision]),
    CONSTRAINT [StepDefinition_WorkflowSchedule_WorkInstructions_Relation1] FOREIGN KEY ([WorkInstructionsId]) REFERENCES [dbo].[WorkInstructions] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [NC_StepDefinition_WorkflowSchedule_SubProcessDefinitionId_SubProcessDefinitionRevision]
    ON [dbo].[StepDefinition_WorkflowSchedule]([SubProcessDefinitionId] ASC, [SubProcessDefinitionRevision] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_StepDefinition_WorkflowSchedule_WorkInstructionsId]
    ON [dbo].[StepDefinition_WorkflowSchedule]([WorkInstructionsId] ASC);

