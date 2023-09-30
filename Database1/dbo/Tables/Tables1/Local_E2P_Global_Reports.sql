CREATE TABLE [dbo].[Local_E2P_Global_Reports] (
    [ReportId]  INT           IDENTITY (1, 1) NOT NULL,
    [Timestamp] DATETIME      NOT NULL,
    [UniqueId]  VARCHAR (255) NOT NULL,
    CONSTRAINT [LocalE2PGlobalReports_PK_ReportId] PRIMARY KEY CLUSTERED ([ReportId] ASC)
);

