CREATE TABLE [dbo].[Report_Tree_Templates] (
    [Report_Tree_Template_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]                INT                  NULL,
    [Report_Tree_Template_Name] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [PK___1__23] PRIMARY KEY CLUSTERED ([Report_Tree_Template_Id] ASC)
);

