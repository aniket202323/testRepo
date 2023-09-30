CREATE TABLE [dbo].[WorkflowDefinition] (
    [AllowMultipleInstances]     BIT              NULL,
    [AssignedLocationAddress]    NVARCHAR (1024)  NULL,
    [AssignedPersonnelAddress]   NVARCHAR (1024)  NULL,
    [CompatabilityVersion]       INT              NULL,
    [DisablePersistence]         BIT              NULL,
    [EnableTracking]             BIT              NULL,
    [RestartAutomatically]       BIT              NULL,
    [TaskPriority]               BIGINT           NULL,
    [TrackingLevel]              NVARCHAR (255)   NULL,
    [WorkflowMetadata]           IMAGE            NULL,
    [CompiledAssembly]           IMAGE            NULL,
    [RequiresRecompile]          BIT              NULL,
    [Valid]                      BIT              NULL,
    [Xoml]                       IMAGE            NULL,
    [CompileErrors]              IMAGE            NULL,
    [Description]                NVARCHAR (255)   NULL,
    [DisplayName]                NVARCHAR (50)    NULL,
    [Enabled]                    BIT              NULL,
    [WorkflowDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowDefinitionRevision] BIGINT           NOT NULL,
    [LastModified]               DATETIME         NULL,
    [UserVersion]                NVARCHAR (128)   NULL,
    [Version]                    BIGINT           NULL,
    [WorkInstructionsId]         UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([WorkflowDefinitionId] ASC, [WorkflowDefinitionRevision] ASC),
    CONSTRAINT [WorkflowDefinition_WorkInstructions_Relation1] FOREIGN KEY ([WorkInstructionsId]) REFERENCES [dbo].[WorkInstructions] ([Id])
);


GO
ALTER TABLE [dbo].[WorkflowDefinition] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_WorkflowDefinition_WorkInstructionsId]
    ON [dbo].[WorkflowDefinition]([WorkInstructionsId] ASC);

