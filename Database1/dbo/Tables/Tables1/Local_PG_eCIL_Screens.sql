CREATE TABLE [dbo].[Local_PG_eCIL_Screens] (
    [ScreenId]      INT          IDENTITY (1, 1) NOT NULL,
    [ScreenDesc]    VARCHAR (50) NOT NULL,
    [DefaultViewId] INT          NULL,
    CONSTRAINT [PK_Local_PG_eCIL_Screens] PRIMARY KEY NONCLUSTERED ([ScreenId] ASC),
    CONSTRAINT [Local_PG_eCIL_Screens_FK_Local_PG_eCIL_UserPreferences] FOREIGN KEY ([DefaultViewId]) REFERENCES [dbo].[Local_PG_eCIL_UserPreferences] ([UP_Id])
);

