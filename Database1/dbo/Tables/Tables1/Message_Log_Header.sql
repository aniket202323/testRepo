CREATE TABLE [dbo].[Message_Log_Header] (
    [Message_Log_Id]       INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Client_Connection_Id] INT           NULL,
    [Message_Info]         VARCHAR (500) NULL,
    [Timestamp]            DATETIME      NOT NULL,
    [Type]                 TINYINT       NULL,
    CONSTRAINT [MsgLogHdr_PK_MsgLogId] PRIMARY KEY NONCLUSTERED ([Message_Log_Id] ASC)
);

