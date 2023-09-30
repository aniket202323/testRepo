CREATE TABLE [dbo].[eSop_Keyword] (
    [Id]              UNIQUEIDENTIFIER NOT NULL,
    [Name]            NVARCHAR (MAX)   NULL,
    [Description]     NVARCHAR (MAX)   NULL,
    [TaskTemplate_Id] UNIQUEIDENTIFIER NOT NULL,
    [Reserved]        BIT              DEFAULT ((0)) NOT NULL,
    [LastModified]    DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_Keyword] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_dbo.eSop_Keyword_dbo.eSop_TaskTemplate_TaskTemplate_Id] FOREIGN KEY ([TaskTemplate_Id]) REFERENCES [dbo].[eSop_TaskTemplate] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_TaskTemplate_Id]
    ON [dbo].[eSop_Keyword]([TaskTemplate_Id] ASC);

