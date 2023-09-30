CREATE TABLE [dbo].[Errors] (
    [Id]            INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [AppId]         INT            NULL,
    [ErrorCode]     INT            NULL,
    [ErrorDesc]     VARCHAR (250)  NULL,
    [ErrorType]     INT            CONSTRAINT [DF_Errors_ErrorType] DEFAULT ((1)) NOT NULL,
    [ExceptionType] VARCHAR (100)  NULL,
    [Parameters]    VARCHAR (1000) NULL,
    [SourceFile]    VARCHAR (250)  NULL,
    [SourceMethod]  VARCHAR (100)  NULL,
    [StackTrace]    VARCHAR (5000) NULL,
    [TimeStamp]     DATETIME       CONSTRAINT [DF_Errors_TimeStamp] DEFAULT (getutcdate()) NOT NULL,
    [UserId]        INT            NULL,
    CONSTRAINT [PK_Errors] PRIMARY KEY CLUSTERED ([Id] ASC)
);

