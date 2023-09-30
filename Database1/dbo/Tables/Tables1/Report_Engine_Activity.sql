CREATE TABLE [dbo].[Report_Engine_Activity] (
    [REA_Id]      INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Engine_Id]   INT           NOT NULL,
    [Engine_Name] VARCHAR (20)  NULL,
    [ErrorLevel]  INT           NULL,
    [Message]     VARCHAR (255) NOT NULL,
    [Report_Id]   INT           NULL,
    [Run_Id]      INT           NULL,
    [Time]        DATETIME      NOT NULL,
    CONSTRAINT [PK_Report_Engine_Activity] PRIMARY KEY NONCLUSTERED ([REA_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ReportEngineActivity_IDX_ReportTime]
    ON [dbo].[Report_Engine_Activity]([Report_Id] ASC, [Time] ASC);

