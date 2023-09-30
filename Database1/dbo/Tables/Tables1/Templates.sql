CREATE TABLE [dbo].[Templates] (
    [Template_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Inherits_Id]   INT                  NULL,
    [Template_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [Templates_PK_TmpId] PRIMARY KEY NONCLUSTERED ([Template_Id] ASC),
    CONSTRAINT [Templates_UC_TmpDesc] UNIQUE NONCLUSTERED ([Template_Desc] ASC)
);

