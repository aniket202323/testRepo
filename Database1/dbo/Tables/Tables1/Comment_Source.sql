CREATE TABLE [dbo].[Comment_Source] (
    [CS_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CS_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [Comment_Source_PK_CSId] PRIMARY KEY CLUSTERED ([CS_Id] ASC),
    CONSTRAINT [Comment_Source_UC_CSDesc] UNIQUE NONCLUSTERED ([CS_Desc] ASC)
);

