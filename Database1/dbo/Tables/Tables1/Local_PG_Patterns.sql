CREATE TABLE [dbo].[Local_PG_Patterns] (
    [PatternID]   INT          IDENTITY (1, 1) NOT NULL,
    [PatternName] VARCHAR (50) NOT NULL,
    [PatternDays] INT          NOT NULL,
    [PatternDesc] NCHAR (255)  NULL,
    CONSTRAINT [PK__Local_PG__0A631B3269A91869] PRIMARY KEY CLUSTERED ([PatternID] ASC)
);

