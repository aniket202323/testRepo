CREATE TABLE [dbo].[LOCAL_PE_HEALTH_LOGCATEGORY] (
    [LogCategory_Id]        INT            IDENTITY (1, 1) NOT NULL,
    [LogCategory_Desc]      NVARCHAR (255) NOT NULL,
    [LogCategory_Comment]   NVARCHAR (MAX) NULL,
    [LogCategory_SortOrder] INT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LOCAL_PE_HEALTH_LOGCATEGORY] PRIMARY KEY CLUSTERED ([LogCategory_Id] ASC)
);

