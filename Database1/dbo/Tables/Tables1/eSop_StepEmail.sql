CREATE TABLE [dbo].[eSop_StepEmail] (
    [Id]                UNIQUEIDENTIFIER NOT NULL,
    [Subject]           NVARCHAR (MAX)   NULL,
    [Message]           NVARCHAR (MAX)   NULL,
    [EventTriggerValue] INT              NOT NULL,
    [Step_Id]           UNIQUEIDENTIFIER NOT NULL,
    [LastModified]      DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_StepEmail] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_dbo.eSop_StepEmail_dbo.eSop_TaskStep_Step_Id] FOREIGN KEY ([Step_Id]) REFERENCES [dbo].[eSop_TaskStep] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_Step_Id]
    ON [dbo].[eSop_StepEmail]([Step_Id] ASC);

