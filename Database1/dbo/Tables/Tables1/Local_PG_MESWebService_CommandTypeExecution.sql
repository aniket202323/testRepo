CREATE TABLE [dbo].[Local_PG_MESWebService_CommandTypeExecution] (
    [Command_Type_Id]              INT NOT NULL,
    [Top_X]                        INT NULL,
    [Last_Id_Sent]                 INT NULL,
    [Retry_Delay]                  INT CONSTRAINT [LocalPGMESWebServiceCommandTypeExecution_DF_RetryDelay] DEFAULT ((0)) NULL,
    [Maximum_Retry_Count]          INT CONSTRAINT [LocalPGMESWebServiceCommandTypeExecution_DF_MaximumRetryCount] DEFAULT ((0)) NULL,
    [Timeout_Retry_Email_Group_Id] INT NULL,
    CONSTRAINT [LocalPGMESWebServiceCommandTypeExecution_PK_CommandTypeId] PRIMARY KEY NONCLUSTERED ([Command_Type_Id] ASC),
    CONSTRAINT [LocalPGMESWebServiceCommandTypeExecution_FK_CommandTypeId] FOREIGN KEY ([Command_Type_Id]) REFERENCES [dbo].[Local_PG_MESWebService_CommandType] ([Command_Type_Id])
);

