CREATE TABLE [dbo].[Operating_Systems] (
    [OS_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [OS_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [Operating_Systems_PK_OSId] PRIMARY KEY CLUSTERED ([OS_Id] ASC),
    CONSTRAINT [Operating_Systems_UC_OSDesc] UNIQUE NONCLUSTERED ([OS_Desc] ASC)
);

