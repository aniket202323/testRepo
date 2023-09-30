CREATE TABLE [dbo].[Local_PG_MESWebService_Transactions] (
    [Transaction_Id]        INT           IDENTITY (1, 1) NOT NULL,
    [Timestamp]             DATETIME      NOT NULL,
    [Command_Type_Id]       INT           NOT NULL,
    [User_Id]               INT           NULL,
    [Input_XML_Data]        VARCHAR (MAX) NULL,
    [Output_XML_Data]       VARCHAR (MAX) NULL,
    [Reprocess_After]       DATETIME      NULL,
    [End_Timestamp]         DATETIME      NULL,
    [Error_Message]         VARCHAR (MAX) NULL,
    [Transaction_Status_Id] INT           CONSTRAINT [LocalPGMESWebServiceTransactions_DF_TransactionStatusId] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [LocalPGMESWebServiceTransactions_PK_TransactionId] PRIMARY KEY CLUSTERED ([Transaction_Id] ASC),
    CONSTRAINT [LocalPGMESWebServiceTransactions_FK_CommandTypeId] FOREIGN KEY ([Command_Type_Id]) REFERENCES [dbo].[Local_PG_MESWebService_CommandType] ([Command_Type_Id]),
    CONSTRAINT [LocalPGMESWebServiceTransactions_FK_TransactionStatusId] FOREIGN KEY ([Transaction_Status_Id]) REFERENCES [dbo].[Local_PG_MESWebService_TransactionStatus] ([Transaction_Status_Id])
);


GO
CREATE NONCLUSTERED INDEX [LocalPGMESWebServiceTransactions_IDX_Timestamp]
    ON [dbo].[Local_PG_MESWebService_Transactions]([Timestamp] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPGMESWebServiceTransactions_IDX_TransactionStatusId]
    ON [dbo].[Local_PG_MESWebService_Transactions]([Transaction_Status_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPGMESWebServiceTransactions_IDX_ReprocessAfter]
    ON [dbo].[Local_PG_MESWebService_Transactions]([Reprocess_After] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPGMESWebServiceTransactions_IDX_CommandTypeId]
    ON [dbo].[Local_PG_MESWebService_Transactions]([Command_Type_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPGMESWebServiceTransactions_IDX_UserId]
    ON [dbo].[Local_PG_MESWebService_Transactions]([User_Id] ASC);

