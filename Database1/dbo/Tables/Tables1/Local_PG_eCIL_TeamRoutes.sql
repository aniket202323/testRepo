CREATE TABLE [dbo].[Local_PG_eCIL_TeamRoutes] (
    [Team_Id]  INT NOT NULL,
    [Route_Id] INT NOT NULL,
    CONSTRAINT [PK_Local_PG_eCIL_TeamRoutes_RouteIdTeamId] PRIMARY KEY CLUSTERED ([Route_Id] ASC, [Team_Id] ASC),
    CONSTRAINT [Local_PG_eCIL_TeamRoutes_FK_Local_PG_eCIL_Routes] FOREIGN KEY ([Route_Id]) REFERENCES [dbo].[Local_PG_eCIL_Routes] ([Route_Id]),
    CONSTRAINT [Local_PG_eCIL_Teams_FK_Local_PG_eCIL_Teams] FOREIGN KEY ([Team_Id]) REFERENCES [dbo].[Local_PG_eCIL_Teams] ([Team_Id])
);

