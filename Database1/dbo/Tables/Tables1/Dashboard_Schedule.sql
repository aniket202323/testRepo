CREATE TABLE [dbo].[Dashboard_Schedule] (
    [Dashboard_Schedule_ID]     INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Calendar_Based]  BIT      NOT NULL,
    [Dashboard_Event_Based]     BIT      NOT NULL,
    [Dashboard_Frequency_Based] BIT      NOT NULL,
    [Dashboard_Last_Run_Time]   DATETIME NOT NULL,
    [dashboard_on_demand_based] BIT      NULL,
    [Dashboard_Report_ID]       INT      NOT NULL,
    CONSTRAINT [PK_Dashboard_Schedule] PRIMARY KEY NONCLUSTERED ([Dashboard_Schedule_ID] ASC),
    CONSTRAINT [DashboardSchedule_UC_ReportId] UNIQUE NONCLUSTERED ([Dashboard_Report_ID] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_Schedule]
    ON [dbo].[Dashboard_Schedule]([Dashboard_Schedule_ID] ASC);

