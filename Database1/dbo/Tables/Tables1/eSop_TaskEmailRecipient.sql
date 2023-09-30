CREATE TABLE [dbo].[eSop_TaskEmailRecipient] (
    [Id]           UNIQUEIDENTIFIER NOT NULL,
    [Address]      NVARCHAR (MAX)   NULL,
    [Email_Id]     UNIQUEIDENTIFIER NOT NULL,
    [LastModified] DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_TaskEmailRecipient] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_dbo.eSop_TaskEmailRecipient_dbo.eSop_TaskEmail_Email_Id] FOREIGN KEY ([Email_Id]) REFERENCES [dbo].[eSop_TaskEmail] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_Email_Id]
    ON [dbo].[eSop_TaskEmailRecipient]([Email_Id] ASC);

