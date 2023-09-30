CREATE TABLE [dbo].[CategoryAssociation_WorkflowSchedule] (
    [Version]                    BIGINT           NULL,
    [WorkflowScheduleId]         UNIQUEIDENTIFIER NOT NULL,
    [WorkflowScheduleRevision]   BIGINT           NOT NULL,
    [CategoryDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [CategoryDefinitionRevision] BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowScheduleId] ASC, [WorkflowScheduleRevision] ASC, [CategoryDefinitionId] ASC, [CategoryDefinitionRevision] ASC),
    CONSTRAINT [CategoryAssociation_WorkflowSchedule_CategoryDefinition_Relation1] FOREIGN KEY ([CategoryDefinitionId], [CategoryDefinitionRevision]) REFERENCES [dbo].[CategoryDefinition] ([CategoryDefinitionId], [CategoryDefinitionRevision]),
    CONSTRAINT [CategoryAssociation_WorkflowSchedule_WorkflowSchedule_Relation1] FOREIGN KEY ([WorkflowScheduleId], [WorkflowScheduleRevision]) REFERENCES [dbo].[WorkflowSchedule] ([WorkflowScheduleId], [WorkflowScheduleRevision])
);


GO
ALTER TABLE [dbo].[CategoryAssociation_WorkflowSchedule] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_CategoryAssociation_WorkflowSchedule_CategoryDefinitionId_CategoryDefinitionRevision]
    ON [dbo].[CategoryAssociation_WorkflowSchedule]([CategoryDefinitionId] ASC, [CategoryDefinitionRevision] ASC);

