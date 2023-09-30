CREATE TABLE [dbo].[Dashboard_Schedule_Frequency] (
    [Dashboard_Schedule_Frequency_ID] INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Frequency]             INT      NOT NULL,
    [Dashboard_Frequency_Base_Time]   DATETIME NOT NULL,
    [Dashboard_Frequency_Type_ID]     INT      NOT NULL,
    [Dashboard_Schedule_ID]           INT      NOT NULL,
    CONSTRAINT [PK_Dashboard_Schedule_Frequency] PRIMARY KEY CLUSTERED ([Dashboard_Schedule_Frequency_ID] ASC)
);

