CREATE TABLE [dbo].[Transactions] (
    [Trans_Id]           INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Approved_By]        INT                  NULL,
    [Approved_On]        DATETIME             NULL,
    [Comment_Id]         INT                  NULL,
    [Corp_Trans_Desc]    VARCHAR (25)         NULL,
    [Corp_Trans_Id]      INT                  NULL,
    [Effective_Date]     DATETIME             NULL,
    [Linked_Server_Id]   INT                  NULL,
    [Prod_Id_Filter_Id]  INT                  NULL,
    [Trans_Create_Date]  DATETIME             NULL,
    [Trans_Desc]         [dbo].[Varchar_Desc] NOT NULL,
    [Trans_Type_Id]      INT                  CONSTRAINT [Transactions_DF_TransTypeId] DEFAULT ((1)) NULL,
    [Transaction_Grp_Id] INT                  NULL,
    [Var_Id_Filter_Id]   INT                  NULL,
    CONSTRAINT [Trans_PK_TransId] PRIMARY KEY CLUSTERED ([Trans_Id] ASC),
    CONSTRAINT [Trans_CC_EffApproved] CHECK ([Effective_Date] IS NULL AND [Approved_By] IS NULL AND [Approved_On] IS NULL OR NOT [Effective_Date] IS NULL AND NOT [Approved_By] IS NULL AND NOT [Approved_On] IS NULL AND [Approved_On]<=[Effective_Date]),
    CONSTRAINT [Trans_FK_ApprovedBy] FOREIGN KEY ([Approved_By]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [Transactions_FK_TransTypeId] FOREIGN KEY ([Trans_Type_Id]) REFERENCES [dbo].[Transaction_Types] ([Trans_Type_Id]),
    CONSTRAINT [TransactionsProd_FK_TranasctionFilterId] FOREIGN KEY ([Prod_Id_Filter_Id]) REFERENCES [dbo].[Transaction_Filter_Values] ([Transaction_Filter_Id]),
    CONSTRAINT [TransactionsVar_FK_TranasctionFilterId] FOREIGN KEY ([Var_Id_Filter_Id]) REFERENCES [dbo].[Transaction_Filter_Values] ([Transaction_Filter_Id]),
    CONSTRAINT [Trans_UC_TransDesc] UNIQUE NONCLUSTERED ([Trans_Desc] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Transactions_IX_ApprovedOn]
    ON [dbo].[Transactions]([Approved_On] DESC);

