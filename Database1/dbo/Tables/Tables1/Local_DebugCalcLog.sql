CREATE TABLE [dbo].[Local_DebugCalcLog] (
    [CalcLogId]  INT            IDENTITY (1, 1) NOT NULL,
    [PUId]       INT            NULL,
    [PUDesc]     VARCHAR (50)   NULL,
    [ObjectName] VARCHAR (50)   NULL,
    [TimeStamp]  DATETIME       NULL,
    [Entry_On]   DATETIME       NULL,
    [CalcErrMsg] VARCHAR (2000) NULL
);

