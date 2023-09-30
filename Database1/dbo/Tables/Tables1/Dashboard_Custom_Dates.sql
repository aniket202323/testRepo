CREATE TABLE [dbo].[Dashboard_Custom_Dates] (
    [Dashboard_Custom_Date_ID] INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Calendar_ID]    INT      NOT NULL,
    [Dashboard_Completed]      BIT      NOT NULL,
    [Dashboard_Day_To_Run]     DATETIME NOT NULL,
    CONSTRAINT [PK_Dashboard_Custom_Dates] PRIMARY KEY CLUSTERED ([Dashboard_Custom_Date_ID] ASC)
);

