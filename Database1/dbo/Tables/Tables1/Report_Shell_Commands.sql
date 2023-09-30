CREATE TABLE [dbo].[Report_Shell_Commands] (
    [Shell_Id]      INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Command]       VARCHAR (255) NOT NULL,
    [Interval]      INT           NOT NULL,
    [Next_Run_Time] DATETIME      NOT NULL,
    CONSTRAINT [PK_Report_Shell_Commands] PRIMARY KEY NONCLUSTERED ([Shell_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ReportShellCommands_IX_NextRunTime]
    ON [dbo].[Report_Shell_Commands]([Next_Run_Time] ASC);

