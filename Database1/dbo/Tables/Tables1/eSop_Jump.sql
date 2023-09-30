CREATE TABLE [dbo].[eSop_Jump] (
    [Id]             UNIQUEIDENTIFIER NOT NULL,
    [Name]           NVARCHAR (MAX)   NULL,
    [JumpToStepName] NVARCHAR (MAX)   NULL,
    [JumpToStepId]   UNIQUEIDENTIFIER NOT NULL,
    [TaskStep_Id]    UNIQUEIDENTIFIER NOT NULL,
    [LastModified]   DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_Jump] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_dbo.eSop_Jump_dbo.eSop_TaskStep_TaskStep_Id] FOREIGN KEY ([TaskStep_Id]) REFERENCES [dbo].[eSop_TaskStep] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_TaskStep_Id]
    ON [dbo].[eSop_Jump]([TaskStep_Id] ASC);

