CREATE TABLE [dbo].[local_Aug262014Morning16Core] (
    [RowNumber]       INT            IDENTITY (0, 1) NOT NULL,
    [EventClass]      INT            NULL,
    [TextData]        NTEXT          NULL,
    [ApplicationName] NVARCHAR (128) NULL,
    [NTUserName]      NVARCHAR (128) NULL,
    [LoginName]       NVARCHAR (128) NULL,
    [Duration]        BIGINT         NULL,
    [ClientProcessID] INT            NULL,
    [SPID]            INT            NULL,
    [StartTime]       DATETIME       NULL,
    [EndTime]         DATETIME       NULL,
    [BinaryData]      IMAGE          NULL,
    PRIMARY KEY CLUSTERED ([RowNumber] ASC)
);

