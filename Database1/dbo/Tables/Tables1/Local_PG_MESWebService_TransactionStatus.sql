CREATE TABLE [dbo].[Local_PG_MESWebService_TransactionStatus] (
    [Transaction_Status_Id]   INT          NOT NULL,
    [Transaction_Status_Desc] VARCHAR (50) NOT NULL,
    CONSTRAINT [LocalPGMESWebServiceTransactionStatus_PK_TransactionStatusId] PRIMARY KEY CLUSTERED ([Transaction_Status_Id] ASC),
    CONSTRAINT [LocalPGMESWebServiceTransactionStatus_UQ_TransactionStatusDesc] UNIQUE NONCLUSTERED ([Transaction_Status_Desc] ASC)
);

