CREATE TABLE [dbo].[Local_PG_ScrapLog] (
    [TagName]   VARCHAR (255) NOT NULL,
    [TimeStamp] DATETIME      NOT NULL,
    [Value]     INT           NOT NULL,
    PRIMARY KEY CLUSTERED ([TimeStamp] ASC, [TagName] ASC)
);

