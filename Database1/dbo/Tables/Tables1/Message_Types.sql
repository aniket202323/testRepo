CREATE TABLE [dbo].[Message_Types] (
    [Description] VARCHAR (70) NOT NULL,
    [Message_Id]  INT          NOT NULL,
    CONSTRAINT [MessageTypes_PK_MessageId] PRIMARY KEY CLUSTERED ([Message_Id] ASC)
);

