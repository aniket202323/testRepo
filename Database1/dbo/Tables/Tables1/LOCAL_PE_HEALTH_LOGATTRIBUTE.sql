﻿CREATE TABLE [dbo].[LOCAL_PE_HEALTH_LOGATTRIBUTE] (
    [LogAttribute_Id]      INT            IDENTITY (1, 1) NOT NULL,
    [LogAttribute_Desc]    NVARCHAR (255) NOT NULL,
    [LogAttribute_Comment] NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_LOCAL_PE_HEALTH_LOGATTRIBUTE] PRIMARY KEY CLUSTERED ([LogAttribute_Id] ASC)
);

