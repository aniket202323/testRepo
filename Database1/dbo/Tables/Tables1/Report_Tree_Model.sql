CREATE TABLE [dbo].[Report_Tree_Model] (
    [Id]                INT            IDENTITY (1, 1) NOT NULL,
    [Report_Name]       VARCHAR (255)  NOT NULL,
    [SQL]               VARCHAR (1000) NULL,
    [Sub_Node_Name]     VARCHAR (255)  NULL,
    [Unit_Level_Report] TINYINT        NOT NULL,
    [URL]               VARCHAR (3000) NULL
);

