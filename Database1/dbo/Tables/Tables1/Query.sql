CREATE TABLE [dbo].[Query] (
    [Id]               INT            NOT NULL,
    [Site]             VARCHAR (255)  NULL,
    [SystemSource]     VARCHAR (255)  NULL,
    [SystemTarget]     VARCHAR (255)  NULL,
    [MessageType]      VARCHAR (255)  NULL,
    [Message]          TEXT           NULL,
    [MainData]         VARCHAR (255)  NULL,
    [InsertedDate]     DATETIME2 (3)  NULL,
    [NextRetryDate]    DATETIME2 (3)  NULL,
    [StartProcessDate] DATETIME2 (3)  NULL,
    [ProcessedDate]    DATETIME2 (3)  NULL,
    [ErrorCode]        INT            NULL,
    [TriggerId]        INT            NULL,
    [errormessage]     VARCHAR (1024) NULL
);

