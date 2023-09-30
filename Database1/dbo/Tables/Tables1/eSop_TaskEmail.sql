CREATE TABLE [dbo].[eSop_TaskEmail] (
    [Id]                UNIQUEIDENTIFIER NOT NULL,
    [Subject]           NVARCHAR (MAX)   NULL,
    [Message]           NVARCHAR (MAX)   NULL,
    [EventTriggerValue] INT              NOT NULL,
    [Task_Id]           UNIQUEIDENTIFIER NOT NULL,
    [LastModified]      DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_TaskEmail] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_dbo.eSop_TaskEmail_dbo.eSop_Task_Task_Id] FOREIGN KEY ([Task_Id]) REFERENCES [dbo].[eSop_Task] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_Task_Id]
    ON [dbo].[eSop_TaskEmail]([Task_Id] ASC);

