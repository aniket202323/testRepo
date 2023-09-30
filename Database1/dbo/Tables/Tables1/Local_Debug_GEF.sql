CREATE TABLE [dbo].[Local_Debug_GEF] (
    [Id]        INT            IDENTITY (1, 1) NOT NULL,
    [timestamp] DATETIME       CONSTRAINT [DF_Local_Debug_GEF_timestamp] DEFAULT (getdate()) NULL,
    [message]   VARCHAR (8000) NULL
);

