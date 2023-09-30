CREATE TABLE [dbo].[User_UnitPreferences] (
    [Unit_PrefId] INT      IDENTITY (1, 1) NOT NULL,
    [ET_Id]       TINYINT  NOT NULL,
    [Modified_On] DATETIME NOT NULL,
    [Profile_Id]  SMALLINT NOT NULL,
    [Pu_Id]       INT      NOT NULL,
    [User_Id]     INT      NOT NULL,
    CONSTRAINT [UserUnitPreferences_PK_UnitPrefId] PRIMARY KEY CLUSTERED ([Unit_PrefId] ASC),
    CONSTRAINT [FK_User_UnitPreferences_EventType] FOREIGN KEY ([ET_Id]) REFERENCES [dbo].[Event_Types] ([ET_Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_User_UnitPreferences_Units] FOREIGN KEY ([Pu_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_User_UnitPreferences_User] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]) ON DELETE CASCADE,
    CONSTRAINT [uc_UnitPreferences] UNIQUE NONCLUSTERED ([User_Id] ASC, [Pu_Id] ASC, [ET_Id] ASC, [Profile_Id] ASC)
);

