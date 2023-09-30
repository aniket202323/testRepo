CREATE TABLE [dbo].[eSop_TaskStepCategory] (
    [Id]           UNIQUEIDENTIFIER NOT NULL,
    [CategoryId]   UNIQUEIDENTIFIER NOT NULL,
    [LastModified] DATETIME         NOT NULL,
    [TaskStep_Id]  UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_dbo.eSop_TaskStepCategory] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_dbo.eSop_TaskStepCategory_dbo.eSop_TaskStep_TaskStep_Id] FOREIGN KEY ([TaskStep_Id]) REFERENCES [dbo].[eSop_TaskStep] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_TaskStep_Id]
    ON [dbo].[eSop_TaskStepCategory]([TaskStep_Id] ASC);

