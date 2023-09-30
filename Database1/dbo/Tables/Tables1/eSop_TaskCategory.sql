CREATE TABLE [dbo].[eSop_TaskCategory] (
    [Id]           UNIQUEIDENTIFIER NOT NULL,
    [CategoryId]   UNIQUEIDENTIFIER NOT NULL,
    [LastModified] DATETIME         NOT NULL,
    [Task_Id]      UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_dbo.eSop_TaskCategory] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_dbo.eSop_TaskCategory_dbo.eSop_Task_Task_Id] FOREIGN KEY ([Task_Id]) REFERENCES [dbo].[eSop_Task] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_Task_Id]
    ON [dbo].[eSop_TaskCategory]([Task_Id] ASC);

