CREATE TABLE [dbo].[Local_PG_ErrorLogDetail] (
    [Detail_Id]            INT              IDENTITY (1, 1) NOT NULL,
    [Error_Id]             UNIQUEIDENTIFIER NOT NULL,
    [Nesting_Level]        INT              NOT NULL,
    [Object_Name]          NVARCHAR (256)   NULL,
    [Error_Section]        VARCHAR (100)    NULL,
    [Error_Message]        NVARCHAR (2048)  NULL,
    [Error_Severity]       INT              NULL,
    [Error_State]          INT              NULL,
    [Error_Severity_Level] INT              NULL,
    [Error_Code]           INT              NULL,
    [TimeStamp]            DATETIME         NULL,
    CONSTRAINT [LocalPGErrorLogDetail_PK_DetailId] PRIMARY KEY CLUSTERED ([Detail_Id] ASC)
);

