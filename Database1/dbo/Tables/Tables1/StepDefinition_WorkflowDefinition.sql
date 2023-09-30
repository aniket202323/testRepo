CREATE TABLE [dbo].[StepDefinition_WorkflowDefinition] (
    [StepDefinitionId]             NVARCHAR (64)    NOT NULL,
    [AssignedLocationAddress]      NVARCHAR (1024)  NULL,
    [AssignedPersonnelAddress]     NVARCHAR (1024)  NULL,
    [Description]                  NVARCHAR (255)   NULL,
    [DisplayName]                  NVARCHAR (50)    NULL,
    [r_Order]                      INT              NULL,
    [LinkedDocumentCount]          INT              NULL,
    [Version]                      BIGINT           NULL,
    [WorkflowDefinitionId]         UNIQUEIDENTIFIER NOT NULL,
    [WorkflowDefinitionRevision]   BIGINT           NOT NULL,
    [SubProcessDefinitionId]       UNIQUEIDENTIFIER NULL,
    [SubProcessDefinitionRevision] BIGINT           NULL,
    [WorkInstructionsId]           UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([WorkflowDefinitionId] ASC, [WorkflowDefinitionRevision] ASC, [StepDefinitionId] ASC),
    CONSTRAINT [StepDefinition_WorkflowDefinition_SubProcessDefinition_Relation1] FOREIGN KEY ([SubProcessDefinitionId], [SubProcessDefinitionRevision]) REFERENCES [dbo].[SubProcessDefinition] ([SubProcessDefinitionId], [SubProcessDefinitionRevision]),
    CONSTRAINT [StepDefinition_WorkflowDefinition_WorkflowDefinition_Relation1] FOREIGN KEY ([WorkflowDefinitionId], [WorkflowDefinitionRevision]) REFERENCES [dbo].[WorkflowDefinition] ([WorkflowDefinitionId], [WorkflowDefinitionRevision]),
    CONSTRAINT [StepDefinition_WorkflowDefinition_WorkInstructions_Relation1] FOREIGN KEY ([WorkInstructionsId]) REFERENCES [dbo].[WorkInstructions] ([Id])
);


GO
ALTER TABLE [dbo].[StepDefinition_WorkflowDefinition] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_StepDefinition_WorkflowDefinition_SubProcessDefinitionId_SubProcessDefinitionRevision]
    ON [dbo].[StepDefinition_WorkflowDefinition]([SubProcessDefinitionId] ASC, [SubProcessDefinitionRevision] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_StepDefinition_WorkflowDefinition_WorkInstructionsId]
    ON [dbo].[StepDefinition_WorkflowDefinition]([WorkInstructionsId] ASC);

