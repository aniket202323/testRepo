CREATE TABLE [dbo].[eSop_TaskStepConfigPanelData] (
    [Id]            UNIQUEIDENTIFIER NOT NULL,
    [ConfigPanelId] NVARCHAR (MAX)   NULL,
    [KeyName]       NVARCHAR (MAX)   NULL,
    [KeyValue]      NVARCHAR (MAX)   NULL,
    [TaskStep_Id]   UNIQUEIDENTIFIER NOT NULL,
    [LastModified]  DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_TaskStepConfigPanelData] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_dbo.eSop_TaskStepConfigPanelData_dbo.eSop_TaskStep_TaskStep_Id] FOREIGN KEY ([TaskStep_Id]) REFERENCES [dbo].[eSop_TaskStep] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_TaskStep_Id]
    ON [dbo].[eSop_TaskStepConfigPanelData]([TaskStep_Id] ASC);

