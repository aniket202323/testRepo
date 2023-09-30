CREATE TABLE [dbo].[Local_PG_Teams] (
    [TeamID]   INT          IDENTITY (1, 1) NOT NULL,
    [TeamName] VARCHAR (10) NOT NULL,
    PRIMARY KEY CLUSTERED ([TeamID] ASC)
);

