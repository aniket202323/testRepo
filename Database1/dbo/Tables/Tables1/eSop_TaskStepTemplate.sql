CREATE TABLE [dbo].[eSop_TaskStepTemplate] (
    [Id]                                UNIQUEIDENTIFIER NOT NULL,
    [Name]                              NVARCHAR (MAX)   NULL,
    [Description]                       NVARCHAR (MAX)   NULL,
    [LinkedSubprocessDefinitionAddress] NVARCHAR (MAX)   NULL,
    [LastModified]                      DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_TaskStepTemplate] PRIMARY KEY CLUSTERED ([Id] ASC)
);

