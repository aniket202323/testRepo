CREATE TABLE [dbo].[Local_Debug_Messages] (
    [Debug_Message_Id]      INT            IDENTITY (1, 1) NOT NULL,
    [Stored_Procedure_Name] VARCHAR (50)   NULL,
    [TimeStamp]             DATETIME       NULL,
    [Message]               VARCHAR (4000) NULL,
    [User]                  VARCHAR (50)   NULL,
    CONSTRAINT [PK_Local_Debug_Messages] PRIMARY KEY CLUSTERED ([Debug_Message_Id] ASC)
);

