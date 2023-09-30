CREATE TABLE [dbo].[Dashboard_Content_Generator_Statistics] (
    [Dashboard_Content_Generator_Statistic_ID] INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Report_End_Time]                DATETIME NULL,
    [Dashboard_Report_ID]                      INT      NOT NULL,
    [Dashboard_Report_Start_Time]              DATETIME NOT NULL,
    CONSTRAINT [PK_Dashboard_Content_Generator_Statistics] PRIMARY KEY NONCLUSTERED ([Dashboard_Content_Generator_Statistic_ID] ASC, [Dashboard_Report_ID] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_Content_Generator_Statistics]
    ON [dbo].[Dashboard_Content_Generator_Statistics]([Dashboard_Content_Generator_Statistic_ID] ASC);

