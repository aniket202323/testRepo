CREATE TABLE [dbo].[Local_PG_eCIL_RouteTasks] (
    [Route_Id]             INT NOT NULL,
    [Var_Id]               INT NOT NULL,
    [Task_Order]           INT NULL,
    [Tour_Stop_Id]         INT NULL,
    [Tour_Stop_Task_Order] INT NULL,
    CONSTRAINT [PK_Local_PG_eCIL_RouteTasks_RouteIdVarId] PRIMARY KEY CLUSTERED ([Route_Id] ASC, [Var_Id] ASC),
    CONSTRAINT [Local_PG_eCIL_RouteTasks_FK_Local_PG_eCIL_Routes] FOREIGN KEY ([Route_Id]) REFERENCES [dbo].[Local_PG_eCIL_Routes] ([Route_Id])
);


GO
CREATE NONCLUSTERED INDEX [Local_PG_eCIL_RouteTasks_IX_VarIdTaskOrder]
    ON [dbo].[Local_PG_eCIL_RouteTasks]([Var_Id] ASC, [Task_Order] ASC);

