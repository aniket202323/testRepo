CREATE TABLE [dbo].[eSop_TaskConfigPanel] (
    [Id]                 UNIQUEIDENTIFIER NOT NULL,
    [TabOrder]           INT              NOT NULL,
    [TabName]            NVARCHAR (MAX)   NULL,
    [PanelLevelValue]    INT              NOT NULL,
    [PanelConfiguration] NVARCHAR (MAX)   NULL,
    [ConfigPanel_Id]     UNIQUEIDENTIFIER NOT NULL,
    [Template_Id]        UNIQUEIDENTIFIER NOT NULL,
    [LastModified]       DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_TaskConfigPanel] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_dbo.eSop_TaskConfigPanel_dbo.eSop_ConfigPanel_ConfigPanel_Id] FOREIGN KEY ([ConfigPanel_Id]) REFERENCES [dbo].[eSop_ConfigPanel] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_dbo.eSop_TaskConfigPanel_dbo.eSop_TaskTemplate_Template_Id] FOREIGN KEY ([Template_Id]) REFERENCES [dbo].[eSop_TaskTemplate] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_ConfigPanel_Id]
    ON [dbo].[eSop_TaskConfigPanel]([ConfigPanel_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Template_Id]
    ON [dbo].[eSop_TaskConfigPanel]([Template_Id] ASC);

