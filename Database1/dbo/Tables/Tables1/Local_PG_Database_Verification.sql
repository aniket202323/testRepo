CREATE TABLE [dbo].[Local_PG_Database_Verification] (
    [ID]           INT           IDENTITY (1, 1) NOT NULL,
    [DatabaseName] VARCHAR (500) NOT NULL,
    [Standard]     VARCHAR (100) NULL,
    [CreatedDate]  DATETIME      NULL,
    CONSTRAINT [PK_Local_PG_Database_Verification] PRIMARY KEY CLUSTERED ([ID] ASC)
);

