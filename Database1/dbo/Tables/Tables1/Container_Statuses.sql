CREATE TABLE [dbo].[Container_Statuses] (
    [Container_Status_Desc] [dbo].[Varchar_Desc] NOT NULL,
    [Container_Status_Id]   INT                  NOT NULL,
    CONSTRAINT [ContStat_PK_ContStatId] PRIMARY KEY NONCLUSTERED ([Container_Status_Id] ASC),
    CONSTRAINT [ContStat_UC_ContStatDesc] UNIQUE NONCLUSTERED ([Container_Status_Desc] ASC)
);

