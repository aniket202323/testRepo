CREATE TABLE [dbo].[Local_PG_Exculed_Databases] (
    [ID]       INT           IDENTITY (1, 1) NOT NULL,
    [Database] VARCHAR (500) NOT NULL,
    CONSTRAINT [PK_Local_PG_Exculed_Databases] PRIMARY KEY CLUSTERED ([ID] ASC)
);

