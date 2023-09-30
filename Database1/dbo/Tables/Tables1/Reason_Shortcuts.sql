CREATE TABLE [dbo].[Reason_Shortcuts] (
    [RS_Id]                INT          IDENTITY (1, 1) NOT NULL,
    [Amount]               REAL         NULL,
    [App_Id]               INT          NOT NULL,
    [PU_Id]                INT          NULL,
    [Reason_Level1]        INT          NULL,
    [Reason_Level2]        INT          NULL,
    [Reason_Level3]        INT          NULL,
    [Reason_Level4]        INT          NULL,
    [Source_PU_Id]         INT          NULL,
    [Shortcut_Name_Global] VARCHAR (25) NULL,
    [Shortcut_Name_Local]  VARCHAR (25) NOT NULL,
    [Shortcut_Name]        AS           (case when (@@options&(512))=(0) then isnull([Shortcut_Name_Global],[Shortcut_Name_Local]) else [Shortcut_Name_Local] end),
    CONSTRAINT [Rsn_Shortcuts_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [Rsn_Shortcuts_FK_RsnLevel1] FOREIGN KEY ([Reason_Level1]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [Rsn_Shortcuts_FK_RsnLevel2] FOREIGN KEY ([Reason_Level2]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [Rsn_Shortcuts_FK_RsnLevel3] FOREIGN KEY ([Reason_Level3]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [Rsn_Shortcuts_FK_RsnLevel4] FOREIGN KEY ([Reason_Level4]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [Rsn_Shortcuts_FK_SrcPUId] FOREIGN KEY ([Source_PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id])
);

