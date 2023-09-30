CREATE TABLE [dbo].[Report_WebPages] (
    [RWP_Id]      INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]  INT           NULL,
    [Detail_Desc] VARCHAR (255) NULL,
    [File_Name]   VARCHAR (50)  NOT NULL,
    [Prompt1]     VARCHAR (50)  NULL,
    [Prompt2]     VARCHAR (50)  NULL,
    [Prompt3]     VARCHAR (50)  NULL,
    [Prompt4]     VARCHAR (50)  NULL,
    [Prompt5]     VARCHAR (50)  NULL,
    [Tab_Title]   VARCHAR (25)  NULL,
    [Title]       VARCHAR (50)  NULL,
    [Version]     VARCHAR (20)  NULL,
    CONSTRAINT [PK_Report_WebPages] PRIMARY KEY NONCLUSTERED ([RWP_Id] ASC),
    CONSTRAINT [Report_WebPages_UC_FileName] UNIQUE NONCLUSTERED ([File_Name] ASC),
    CONSTRAINT [Report_WebPages_UC_Title] UNIQUE NONCLUSTERED ([Title] ASC)
);

