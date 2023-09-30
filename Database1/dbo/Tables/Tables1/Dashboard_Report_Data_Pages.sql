CREATE TABLE [dbo].[Dashboard_Report_Data_Pages] (
    [Page_ID]     INT  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Page_XML]    TEXT NOT NULL,
    [Report_ID]   INT  NOT NULL,
    [Report_Page] INT  NOT NULL,
    CONSTRAINT [PK_Dashboard_Report_Data_Pages] PRIMARY KEY CLUSTERED ([Page_ID] ASC)
);

