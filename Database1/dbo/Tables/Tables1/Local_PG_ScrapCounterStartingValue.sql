CREATE TABLE [dbo].[Local_PG_ScrapCounterStartingValue] (
    [PUId]       INT           NOT NULL,
    [EventId]    INT           NOT NULL,
    [TagName]    VARCHAR (255) NOT NULL,
    [StartValue] INT           NOT NULL,
    PRIMARY KEY CLUSTERED ([PUId] ASC, [EventId] ASC, [TagName] ASC)
);

