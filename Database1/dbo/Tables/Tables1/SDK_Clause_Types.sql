CREATE TABLE [dbo].[SDK_Clause_Types] (
    [ClauseId]    INT           IDENTITY (1, 1) NOT NULL,
    [ClauseName]  VARCHAR (100) NOT NULL,
    [Description] VARCHAR (500) NULL,
    CONSTRAINT [SDK_Clause_Data_PK_ClauseId] PRIMARY KEY CLUSTERED ([ClauseId] ASC)
);

