CREATE TABLE [dbo].[Local_DebugEventLog] (
    [EventLogId]   INT            IDENTITY (1, 1) NOT NULL,
    [Entry_On]     DATETIME       NOT NULL,
    [TimeStamp]    DATETIME       NULL,
    [ECId]         INT            NOT NULL,
    [PUDesc]       VARCHAR (50)   NULL,
    [ObjectName]   VARCHAR (255)  NOT NULL,
    [TriggerNum]   VARCHAR (50)   NULL,
    [TriggerValue] VARCHAR (50)   NULL,
    [SpareField01] VARCHAR (50)   NULL,
    [SpareField02] VARCHAR (50)   NULL,
    [SpareField03] VARCHAR (50)   NULL,
    [EventMsg]     VARCHAR (1000) NULL
);

