CREATE TABLE [dbo].[User_Parameter_XRef] (
    [Parm_Id]                INT NOT NULL,
    [User_Id]                INT NOT NULL,
    [User_Parameter_XRef_Id] INT NOT NULL,
    CONSTRAINT [UserParameterXRef_UC_ParmIdUserId] UNIQUE NONCLUSTERED ([Parm_Id] ASC, [User_Id] ASC)
);

