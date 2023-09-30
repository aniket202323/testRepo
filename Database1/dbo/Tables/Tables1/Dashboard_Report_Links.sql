CREATE TABLE [dbo].[Dashboard_Report_Links] (
    [Dashboard_Report_Link_ID]   INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Report_From_ID]   INT NOT NULL,
    [Dashboard_Report_To_ID]     INT NULL,
    [Dashboard_Template_Link_ID] INT NOT NULL,
    CONSTRAINT [PK_Dashboard_Report_Links] PRIMARY KEY CLUSTERED ([Dashboard_Report_Link_ID] ASC)
);

