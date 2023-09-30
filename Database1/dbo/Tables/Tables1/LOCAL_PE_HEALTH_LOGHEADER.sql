CREATE TABLE [dbo].[LOCAL_PE_HEALTH_LOGHEADER] (
    [LogHeader_Id]   INT            IDENTITY (1, 1) NOT NULL,
    [LogType_Id]     INT            NOT NULL,
    [LogCategory_Id] INT            NOT NULL,
    [Entry_On]       DATETIME       NOT NULL,
    [User_Id]        INT            NOT NULL,
    [Message]        NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_LogHeader_Id] PRIMARY KEY CLUSTERED ([LogHeader_Id] ASC),
    CONSTRAINT [FK_HEALTH_LOGHEADER_HEALTH_LOGCATEGORY] FOREIGN KEY ([LogCategory_Id]) REFERENCES [dbo].[LOCAL_PE_HEALTH_LOGCATEGORY] ([LogCategory_Id]),
    CONSTRAINT [FK_HEALTH_LOGHEADER_HEALTH_LOGTYPE] FOREIGN KEY ([LogType_Id]) REFERENCES [dbo].[LOCAL_PE_HEALTH_LOGTYPE] ([LogType_Id])
);

