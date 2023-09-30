CREATE TABLE [dbo].[Local_CTS_Debug_Log] (
    [DL_ID]      INT           IDENTITY (1, 1) NOT NULL,
    [Timestamp]  DATETIME      NULL,
    [CallingSP]  VARCHAR (50)  NULL,
    [LogNumber]  INT           NULL,
    [Message]    VARCHAR (255) NULL,
    [GroupingId] VARCHAR (50)  NULL
);

