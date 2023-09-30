CREATE TABLE [dbo].[WorkflowSchedule] (
    [AllowMultipleInstances]         BIT              NULL,
    [AssignedLocationAddress]        NVARCHAR (1024)  NULL,
    [AssignedPersonnelAddress]       NVARCHAR (1024)  NULL,
    [IsTaskVisibleInStartTaskWindow] BIT              NULL,
    [StartTaskLocationAddress]       NVARCHAR (1024)  NULL,
    [StartTaskPersonnelAddress]      NVARCHAR (1024)  NULL,
    [EnableTracking]                 BIT              NULL,
    [TaskPriority]                   BIGINT           NULL,
    [OverrideTracking]               BIT              NULL,
    [TrackingLevel]                  NVARCHAR (255)   NULL,
    [WorkInstructions]               IMAGE            NULL,
    [Description]                    NVARCHAR (255)   NULL,
    [DisplayName]                    NVARCHAR (50)    NULL,
    [Enabled]                        BIT              NULL,
    [WorkflowScheduleId]             UNIQUEIDENTIFIER NOT NULL,
    [WorkflowScheduleRevision]       BIGINT           NOT NULL,
    [LastModified]                   DATETIME         NULL,
    [UserVersion]                    NVARCHAR (128)   NULL,
    [Version]                        BIGINT           NULL,
    [WorkflowDefinitionId]           UNIQUEIDENTIFIER NULL,
    [WorkflowDefinitionRevision]     BIGINT           NULL,
    [WorkInstructionsId]             UNIQUEIDENTIFIER NULL,
    [ItemId]                         UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([WorkflowScheduleId] ASC, [WorkflowScheduleRevision] ASC),
    CONSTRAINT [WorkflowSchedule_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [WorkflowSchedule_WorkflowDefinition_Relation1] FOREIGN KEY ([WorkflowDefinitionId], [WorkflowDefinitionRevision]) REFERENCES [dbo].[WorkflowDefinition] ([WorkflowDefinitionId], [WorkflowDefinitionRevision]),
    CONSTRAINT [WorkflowSchedule_WorkInstructions_Relation1] FOREIGN KEY ([WorkInstructionsId]) REFERENCES [dbo].[WorkInstructions] ([Id])
);


GO
ALTER TABLE [dbo].[WorkflowSchedule] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_WorkflowSchedule_WorkflowDefinitionId_WorkflowDefinitionRevision]
    ON [dbo].[WorkflowSchedule]([WorkflowDefinitionId] ASC, [WorkflowDefinitionRevision] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_WorkflowSchedule_WorkInstructionsId]
    ON [dbo].[WorkflowSchedule]([WorkInstructionsId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_WorkflowSchedule_ItemId]
    ON [dbo].[WorkflowSchedule]([ItemId] ASC);

