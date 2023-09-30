CREATE TABLE [dbo].[Dashboard_Report_Data] (
    [Dashboard_Report_Data_ID]      INT        IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Report_Display_Name] CHAR (100) NOT NULL,
    [Dashboard_Report_ID]           INT        NOT NULL,
    [Dashboard_Report_Version]      INT        NOT NULL,
    [Dashboard_Report_XML]          TEXT       NOT NULL,
    [Dashboard_Time_Stamp]          DATETIME   NOT NULL,
    CONSTRAINT [PK_Dashboard_Report_Data] PRIMARY KEY NONCLUSTERED ([Dashboard_Report_Data_ID] ASC, [Dashboard_Report_ID] ASC, [Dashboard_Report_Version] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_Report_Data]
    ON [dbo].[Dashboard_Report_Data]([Dashboard_Report_Data_ID] ASC);

