CREATE TABLE [dbo].[SubProcessDefinition] (
    [CompiledAssembly]             IMAGE            NULL,
    [RequiresRecompile]            BIT              NULL,
    [Valid]                        BIT              NULL,
    [Xoml]                         IMAGE            NULL,
    [CompileErrors]                IMAGE            NULL,
    [Description]                  NVARCHAR (255)   NULL,
    [DisplayName]                  NVARCHAR (50)    NULL,
    [Enabled]                      BIT              NULL,
    [SubProcessDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [SubProcessDefinitionRevision] BIGINT           NOT NULL,
    [LastModified]                 DATETIME         NULL,
    [UserVersion]                  NVARCHAR (128)   NULL,
    [Version]                      BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([SubProcessDefinitionId] ASC, [SubProcessDefinitionRevision] ASC)
);


GO
ALTER TABLE [dbo].[SubProcessDefinition] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);

