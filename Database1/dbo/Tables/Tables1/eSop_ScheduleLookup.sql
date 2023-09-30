CREATE TABLE [dbo].[eSop_ScheduleLookup] (
    [Id]           UNIQUEIDENTIFIER NOT NULL,
    [ScheduleId]   UNIQUEIDENTIFIER NOT NULL,
    [Task_Id]      UNIQUEIDENTIFIER NOT NULL,
    [LastModified] DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_ScheduleLookup] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_dbo.eSop_ScheduleLookup_dbo.eSop_Task_Task_Id] FOREIGN KEY ([Task_Id]) REFERENCES [dbo].[eSop_Task] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_Task_Id]
    ON [dbo].[eSop_ScheduleLookup]([Task_Id] ASC);

