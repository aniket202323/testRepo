CREATE TABLE [dbo].[LOCAL_PE_HEALTH_LOGTYPE] (
    [LogType_Id]        INT            IDENTITY (1, 1) NOT NULL,
    [LogType_Desc]      NVARCHAR (255) NOT NULL,
    [LogType_IsActive]  BIT            DEFAULT ((1)) NOT NULL,
    [LogType_Comment]   NVARCHAR (MAX) NULL,
    [LogCategory_Id]    INT            DEFAULT ((1)) NOT NULL,
    [LogType_IsVisible] BIT            DEFAULT ((1)) NOT NULL,
    [LogType_SortOrder] INT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LOCAL_PE_HEALTH_LOGTYPE] PRIMARY KEY CLUSTERED ([LogType_Id] ASC),
    CONSTRAINT [FK_HEALTH_LOGTYPE_HEALTH_LOGCATEGORY] FOREIGN KEY ([LogCategory_Id]) REFERENCES [dbo].[LOCAL_PE_HEALTH_LOGCATEGORY] ([LogCategory_Id])
);

