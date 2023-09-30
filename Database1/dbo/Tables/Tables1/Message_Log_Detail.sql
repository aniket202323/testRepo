CREATE TABLE [dbo].[Message_Log_Detail] (
    [Message_Log_Detail_Id] INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Message]               VARCHAR (8000) NULL,
    [Message_Log_Id]        INT            NOT NULL,
    CONSTRAINT [MsgLogDet_PK_MsgLogDetId] PRIMARY KEY NONCLUSTERED ([Message_Log_Detail_Id] ASC)
);

