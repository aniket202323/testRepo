CREATE TABLE [dbo].[eSop_TaskTemplate] (
    [Id]                              UNIQUEIDENTIFIER NOT NULL,
    [Name]                            NVARCHAR (MAX)   NULL,
    [Description]                     NVARCHAR (MAX)   NULL,
    [LinkedWorkflowDefinitionAddress] NVARCHAR (MAX)   NULL,
    [TemplateTypeValue]               INT              NOT NULL,
    [LastModified]                    DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_TaskTemplate] PRIMARY KEY CLUSTERED ([Id] ASC)
);

