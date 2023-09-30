CREATE TABLE [dbo].[UserActivityDefinition] (
    [CompiledAssembly]               IMAGE            NULL,
    [RequiresRecompile]              BIT              NULL,
    [Valid]                          BIT              NULL,
    [Xoml]                           IMAGE            NULL,
    [CompileErrors]                  IMAGE            NULL,
    [Description]                    NVARCHAR (255)   NULL,
    [DisplayName]                    NVARCHAR (50)    NULL,
    [Enabled]                        BIT              NULL,
    [UserActivityDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [UserActivityDefinitionRevision] BIGINT           NOT NULL,
    [LastModified]                   DATETIME         NULL,
    [UserVersion]                    NVARCHAR (128)   NULL,
    [Version]                        BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([UserActivityDefinitionId] ASC, [UserActivityDefinitionRevision] ASC)
);

