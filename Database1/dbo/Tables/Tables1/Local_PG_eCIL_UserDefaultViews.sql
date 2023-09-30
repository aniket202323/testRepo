CREATE TABLE [dbo].[Local_PG_eCIL_UserDefaultViews] (
    [User_Id]  INT NOT NULL,
    [ScreenId] INT NOT NULL,
    [UP_Id]    INT NULL,
    CONSTRAINT [PK_Local_PG_eCIL_UserDefaultViews] PRIMARY KEY NONCLUSTERED ([User_Id] ASC, [ScreenId] ASC),
    CONSTRAINT [Local_PG_eCIL_UserDefaultViews_FK_Local_PG_eCIL_Screens] FOREIGN KEY ([ScreenId]) REFERENCES [dbo].[Local_PG_eCIL_Screens] ([ScreenId]),
    CONSTRAINT [Local_PG_eCIL_UserDefaultViews_FK_Local_PG_eCIL_UserPreferences] FOREIGN KEY ([UP_Id]) REFERENCES [dbo].[Local_PG_eCIL_UserPreferences] ([UP_Id]),
    CONSTRAINT [Local_PG_eCIL_UserDefaultViews_FK_Users_Base] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);

