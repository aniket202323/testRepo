CREATE TABLE [dbo].[Local_SSI_ErrorLogHeader] (
    [Header_Id]           INT              IDENTITY (1, 1) NOT NULL,
    [Error_Id]            UNIQUEIDENTIFIER NOT NULL,
    [Primary_Object_Name] NVARCHAR (256)   NOT NULL,
    [TimeStamp]           DATETIME         NOT NULL,
    [Is_Reported]         BIT              NULL,
    [KeyId]               INT              NULL,
    [TableId]             INT              NULL,
    CONSTRAINT [LocalSSIErrorLogHeader_PK_HeaderId] PRIMARY KEY CLUSTERED ([Header_Id] ASC)
);

