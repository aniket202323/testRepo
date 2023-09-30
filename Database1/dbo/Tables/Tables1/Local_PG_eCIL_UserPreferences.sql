CREATE TABLE [dbo].[Local_PG_eCIL_UserPreferences] (
    [UP_Id]        INT            IDENTITY (1, 1) NOT NULL,
    [ViewType]     INT            NOT NULL,
    [User_Id]      INT            NOT NULL,
    [Profile_Desc] VARCHAR (100)  NOT NULL,
    [Data]         VARCHAR (7000) NOT NULL,
    [ScreenId]     INT            NOT NULL,
    [IsPublic]     BIT            DEFAULT ((0)) NULL,
    [IsWrapEnable] BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Local_PG_eCIL_UserPreferences] PRIMARY KEY NONCLUSTERED ([UP_Id] ASC),
    CONSTRAINT [Local_PG_eCIL_UserPreferences_FK_Users_Base] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);

