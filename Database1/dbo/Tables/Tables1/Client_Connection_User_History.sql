CREATE TABLE [dbo].[Client_Connection_User_History] (
    [CCS_Id]               TINYINT      NOT NULL,
    [Client_Connection_Id] INT          NOT NULL,
    [TimeStamp]            DATETIME     NOT NULL,
    [User_Id]              INT          NULL,
    [Username]             VARCHAR (30) NOT NULL,
    CONSTRAINT [CCUserHistory_FK_CCStatuses] FOREIGN KEY ([CCS_Id]) REFERENCES [dbo].[Client_Connection_Statuses] ([CCS_Id]),
    CONSTRAINT [CCUserHistory_FK_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE NONCLUSTERED INDEX [Client_Connection_User_History_IX_CliConnId]
    ON [dbo].[Client_Connection_User_History]([Client_Connection_Id] ASC);

