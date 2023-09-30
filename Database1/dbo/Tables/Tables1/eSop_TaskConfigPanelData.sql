CREATE TABLE [dbo].[eSop_TaskConfigPanelData] (
    [Id]            UNIQUEIDENTIFIER NOT NULL,
    [ConfigPanelId] NVARCHAR (MAX)   NULL,
    [KeyName]       NVARCHAR (MAX)   NULL,
    [KeyValue]      NVARCHAR (MAX)   NULL,
    [Task_Id]       UNIQUEIDENTIFIER NOT NULL,
    [LastModified]  DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_TaskConfigPanelData] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_dbo.eSop_TaskConfigPanelData_dbo.eSop_Task_Task_Id] FOREIGN KEY ([Task_Id]) REFERENCES [dbo].[eSop_Task] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_Task_Id]
    ON [dbo].[eSop_TaskConfigPanelData]([Task_Id] ASC);

