CREATE TABLE [dbo].[Server_Log_Records] (
    [Record_Order]      INT            IDENTITY (1, 1) NOT NULL,
    [Message]           VARCHAR (5000) NULL,
    [Message_TimeStamp] DATETIME       NULL,
    [Service_Desc]      VARCHAR (50)   NOT NULL,
    [Timestamp]         DATETIME       NOT NULL
);


GO
CREATE CLUSTERED INDEX [Server_Log_Records_IX_SvcTSOrder]
    ON [dbo].[Server_Log_Records]([Service_Desc] ASC, [Timestamp] ASC, [Record_Order] ASC);


GO
CREATE NONCLUSTERED INDEX [ServerLog_IDX_Timestamp]
    ON [dbo].[Server_Log_Records]([Timestamp] ASC);


GO
CREATE NONCLUSTERED INDEX [ServerLog_IDX_ServiceDesc]
    ON [dbo].[Server_Log_Records]([Service_Desc] ASC);

