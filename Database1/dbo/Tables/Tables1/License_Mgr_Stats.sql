CREATE TABLE [dbo].[License_Mgr_Stats] (
    [Average_Users]       FLOAT (53)   NOT NULL,
    [Count_For_Average]   INT          NOT NULL,
    [Maximum_Old_Clients] INT          NOT NULL,
    [Maximum_Users]       INT          NOT NULL,
    [Minimum_Users]       INT          NOT NULL,
    [Module_Id]           INT          NOT NULL,
    [Month_Id]            VARCHAR (10) NOT NULL,
    CONSTRAINT [PK_License_Mgr_Stats] PRIMARY KEY CLUSTERED ([Month_Id] ASC, [Module_Id] ASC)
);

