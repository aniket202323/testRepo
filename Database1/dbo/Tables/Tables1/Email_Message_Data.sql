CREATE TABLE [dbo].[Email_Message_Data] (
    [EG_Id]           INT            NULL,
    [Message_id]      INT            NOT NULL,
    [Message_Subject] VARCHAR (2000) NOT NULL,
    [Message_Text]    VARCHAR (2000) NULL,
    [Severity]        TINYINT        NULL,
    CONSTRAINT [EmailMessageData_PK_MessageId] PRIMARY KEY CLUSTERED ([Message_id] ASC),
    CONSTRAINT [EmailMessageData_FK_EGId] FOREIGN KEY ([EG_Id]) REFERENCES [dbo].[Email_Groups] ([EG_Id])
);

