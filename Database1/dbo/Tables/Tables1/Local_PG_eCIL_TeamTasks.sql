CREATE TABLE [dbo].[Local_PG_eCIL_TeamTasks] (
    [Team_Id] INT NOT NULL,
    [Var_Id]  INT NOT NULL,
    CONSTRAINT [PK_Local_PG_eCIL_TeamTasks_VarIdTeamId] PRIMARY KEY CLUSTERED ([Var_Id] ASC, [Team_Id] ASC),
    CONSTRAINT [Local_PG_eCIL_TeamTasks_FK_Local_PG_eCIL_Teams] FOREIGN KEY ([Team_Id]) REFERENCES [dbo].[Local_PG_eCIL_Teams] ([Team_Id])
);

