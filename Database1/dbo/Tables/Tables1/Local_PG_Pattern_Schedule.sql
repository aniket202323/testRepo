CREATE TABLE [dbo].[Local_PG_Pattern_Schedule] (
    [ScheduleID]    INT         IDENTITY (1, 1) NOT NULL,
    [PatternID]     INT         NOT NULL,
    [PatternDayID]  INT         NOT NULL,
    [ShiftID]       INT         NOT NULL,
    [TeamID]        INT         NOT NULL,
    [StartTime]     VARCHAR (5) NOT NULL,
    [EndTime]       VARCHAR (5) NOT NULL,
    [DayChangeFlag] INT         NULL,
    PRIMARY KEY CLUSTERED ([ScheduleID] ASC)
);

