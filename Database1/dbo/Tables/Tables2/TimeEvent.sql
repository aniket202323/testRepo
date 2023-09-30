CREATE TABLE [dbo].[TimeEvent] (
    [StartTime]         DATETIME         NULL,
    [RecurrenceType]    NVARCHAR (255)   NULL,
    [EndTimeSet]        BIT              NULL,
    [EndTime]           DATETIME         NULL,
    [TimeSpanInterval]  BIGINT           NULL,
    [TimeSpanOffset]    BIGINT           NULL,
    [DailyInterval]     INT              NULL,
    [WeeklyInterval]    INT              NULL,
    [DayOfWeekMask]     INT              NULL,
    [MonthlyInterval]   INT              NULL,
    [DayOfMonth]        INT              NULL,
    [DayRecurrenceType] INT              NULL,
    [DayOfWeek]         INT              NULL,
    [TimeEventId]       UNIQUEIDENTIFIER NOT NULL,
    [Name]              NVARCHAR (255)   NULL,
    [Description]       NVARCHAR (1024)  NULL,
    [Enabled]           BIT              NULL,
    [Version]           BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([TimeEventId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TimeEvent_Name]
    ON [dbo].[TimeEvent]([Name] ASC);

