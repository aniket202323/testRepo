CREATE TABLE [dbo].[Local_PG_eCIL_TeamUsers] (
    [Team_Id] INT NOT NULL,
    [User_Id] INT NOT NULL,
    CONSTRAINT [PK_Local_PG_eCIL_TeamUsers_UserIdTeamId] PRIMARY KEY CLUSTERED ([User_Id] ASC, [Team_Id] ASC),
    CONSTRAINT [Local_PG_eCIL_TeamUsers_FK_Local_PG_eCIL_Teams] FOREIGN KEY ([Team_Id]) REFERENCES [dbo].[Local_PG_eCIL_Teams] ([Team_Id]),
    CONSTRAINT [Local_PG_eCIL_TeamUsers_FK_Users_Base] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);

