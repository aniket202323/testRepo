CREATE TABLE [dbo].[Transaction_Filter_Values] (
    [Transaction_Filter_Id] INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Value]                 VARCHAR (3000) NOT NULL,
    CONSTRAINT [TransactionFilterValues_PK_FilterId] PRIMARY KEY NONCLUSTERED ([Transaction_Filter_Id] ASC)
);

