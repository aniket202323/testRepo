CREATE TABLE [dbo].[Dashboard_Day_Of_Week] (
    [Dashboard_Day_Of_Week_ID] INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Calendar_ID]    INT NOT NULL,
    [Dashboard_Day_Of_Week]    INT NOT NULL,
    CONSTRAINT [PK_Dashboard_Day_Of_Week] PRIMARY KEY CLUSTERED ([Dashboard_Day_Of_Week_ID] ASC)
);

