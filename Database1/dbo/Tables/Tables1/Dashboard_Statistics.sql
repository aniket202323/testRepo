CREATE TABLE [dbo].[Dashboard_Statistics] (
    [Statistic_ID]  INT           IDENTITY (1, 1) NOT NULL,
    [Dashboard_Key] VARCHAR (100) NOT NULL,
    [Last_Access]   DATETIME      NOT NULL,
    [Number_Hits]   INT           NOT NULL
);

