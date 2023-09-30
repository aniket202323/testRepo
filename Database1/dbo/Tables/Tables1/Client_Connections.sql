CREATE TABLE [dbo].[Client_Connections] (
    [Client_Connection_Id] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [AppDesc]              VARCHAR (100) NULL,
    [Client_OS]            VARCHAR (100) NULL,
    [End_Time]             DATETIME      NULL,
    [HostName]             VARCHAR (50)  NOT NULL,
    [Language_Id]          INT           NULL,
    [Last_Heartbeat]       DATETIME      NULL,
    [LocalId]              INT           NULL,
    [Process_ID]           INT           NOT NULL,
    [Start_Time]           DATETIME      NOT NULL,
    CONSTRAINT [CliConn_PK_CliConnId] PRIMARY KEY NONCLUSTERED ([Client_Connection_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [Client_Connections_IX_EndTimeLastHeartbeat]
    ON [dbo].[Client_Connections]([End_Time] ASC, [Last_Heartbeat] ASC);


GO
CREATE NONCLUSTERED INDEX [Client_Connections_IX_StartTimeId]
    ON [dbo].[Client_Connections]([Start_Time] ASC, [Client_Connection_Id] ASC);

