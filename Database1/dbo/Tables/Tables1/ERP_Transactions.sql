CREATE TABLE [dbo].[ERP_Transactions] (
    [ActualId] INT      NOT NULL,
    [DBTT_Id]  INT      NOT NULL,
    [Entry_On] DATETIME NOT NULL,
    [Table_Id] INT      NOT NULL,
    CONSTRAINT [ERPTransactions_FK_TableId] FOREIGN KEY ([Table_Id]) REFERENCES [dbo].[Tables] ([TableId])
);


GO
CREATE NONCLUSTERED INDEX [ERPTrans_IX_TableIdEntryOnActualId]
    ON [dbo].[ERP_Transactions]([Table_Id] ASC, [Entry_On] ASC, [ActualId] ASC);

