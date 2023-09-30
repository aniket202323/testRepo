CREATE TABLE [dbo].[eSop_LinkedDocument] (
    [Id]           UNIQUEIDENTIFIER NOT NULL,
    [Name]         NVARCHAR (MAX)   NULL,
    [Url]          NVARCHAR (MAX)   NULL,
    [TaskStep_Id]  UNIQUEIDENTIFIER NOT NULL,
    [LastModified] DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_LinkedDocument] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_dbo.eSop_LinkedDocument_dbo.eSop_TaskStep_TaskStep_Id] FOREIGN KEY ([TaskStep_Id]) REFERENCES [dbo].[eSop_TaskStep] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_TaskStep_Id]
    ON [dbo].[eSop_LinkedDocument]([TaskStep_Id] ASC);

