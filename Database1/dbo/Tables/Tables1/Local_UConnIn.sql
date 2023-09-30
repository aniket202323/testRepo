CREATE TABLE [dbo].[Local_UConnIn] (
    [Id]              INT            IDENTITY (1, 1) NOT NULL,
    [TransactionId]   BIGINT         NULL,
    [TransactionType] VARCHAR (1)    NULL,
    [MessageType]     VARCHAR (255)  NULL,
    [MessageBody]     VARCHAR (7000) NULL,
    [CreationDate]    DATETIME       NULL,
    [ProcessDate]     DATETIME       NULL,
    [ErrorCode]       INT            NULL,
    [NextRetry]       DATETIME       NULL,
    [Message]         NVARCHAR (255) NULL,
    [Source]          VARCHAR (50)   NULL,
    CONSTRAINT [PK_Local_UConnIn] PRIMARY KEY CLUSTERED ([Id] ASC)
);

