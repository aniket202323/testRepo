CREATE TABLE [dbo].[eSop_StepEmailRecipient] (
    [Id]           UNIQUEIDENTIFIER NOT NULL,
    [Address]      NVARCHAR (MAX)   NULL,
    [Email_Id]     UNIQUEIDENTIFIER NOT NULL,
    [LastModified] DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_StepEmailRecipient] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_dbo.eSop_StepEmailRecipient_dbo.eSop_StepEmail_Email_Id] FOREIGN KEY ([Email_Id]) REFERENCES [dbo].[eSop_StepEmail] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_Email_Id]
    ON [dbo].[eSop_StepEmailRecipient]([Email_Id] ASC);

