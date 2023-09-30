CREATE TABLE [dbo].[eSop_TaskTemplateMetadata] (
    [Id]           UNIQUEIDENTIFIER NOT NULL,
    [Name]         NVARCHAR (MAX)   NULL,
    [Value]        NVARCHAR (MAX)   NULL,
    [Template_Id]  UNIQUEIDENTIFIER NOT NULL,
    [LastModified] DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_TaskTemplateMetadata] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_dbo.eSop_TaskTemplateMetadata_dbo.eSop_TaskTemplate_Template_Id] FOREIGN KEY ([Template_Id]) REFERENCES [dbo].[eSop_TaskTemplate] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_Template_Id]
    ON [dbo].[eSop_TaskTemplateMetadata]([Template_Id] ASC);

