CREATE TABLE [dbo].[Local_PG_eCIL_TeamCrewRoutes] (
    [Crew_Desc] VARCHAR (10) NOT NULL,
    [Team_Id]   INT          NOT NULL,
    [Line_Id]   INT          NOT NULL,
    [Route_Id]  INT          NOT NULL,
    CONSTRAINT [FK_Local_pg_eCIL_CrewTeams_Local_PG_eCIL_Teams] FOREIGN KEY ([Team_Id]) REFERENCES [dbo].[Local_PG_eCIL_Teams] ([Team_Id])
);

