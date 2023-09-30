CREATE TABLE [dbo].[Dashboard_Calendar] (
    [Dashboard_Calendar_ID]      INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Custom_Date]      BIT NOT NULL,
    [Dashboard_Day_Of_Week]      BIT NOT NULL,
    [Dashboard_First_of_Month]   BIT NOT NULL,
    [Dashboard_First_Of_Quarter] BIT NOT NULL,
    [Dashboard_First_Of_Year]    BIT NOT NULL,
    [Dashboard_Last_of_Month]    BIT NOT NULL,
    [Dashboard_Last_Of_Quarter]  BIT NOT NULL,
    [Dashboard_Last_Of_Year]     BIT NOT NULL,
    [Dashboard_Schedule_ID]      INT NOT NULL,
    CONSTRAINT [PK_Dashboard_Calendar] PRIMARY KEY NONCLUSTERED ([Dashboard_Calendar_ID] ASC, [Dashboard_Schedule_ID] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_Calendar]
    ON [dbo].[Dashboard_Calendar]([Dashboard_Calendar_ID] ASC);

